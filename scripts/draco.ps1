param(
  [switch]$install = $false,
  [string]$source_folder = '../public',
  [string]$draco_encoder = './draco/build/Release/draco_encoder.exe'
)
if ($args[0] -in @('-h', 'help')) {
  Write-Host '-install ='$install', Forces draco encoder reinstall (requires cmake, python3, c++ build tools)'
  Write-Host '-source_folder ='$source_folder', Folder of assets to be compressed'
  Write-Host '-draco_encoder ='$draco_encoder', Decoder path'
  return;
}

#region Install
function AssertDependencies {
  try {
    py --version
  }
  catch {
    try {
      python --version
    }
    catch {
      Write-Host "Missing dependency Python: (https://www.python.org/downloads/)"
      return $false;
    }
  }
  try {
    cmdake --version
  }
  catch {
    Write-Host "Missing dependency CMake: (https://cmake.org/download/)"
    return $false;
  }
  
  return $true
}
function InstallDraco {
  if (Test-Path './draco') {
    npx rimraf ./draco
  }
  $script_dir = Resolve-Path "."
  git clone https://github.com/google/draco
  mkdir ./draco/build | Set-Location
  git submodule update --init
  cmake ../ -DDRACO_TRANSCODER_SUPPORTED=ON
  cmake --build . --config Release
  
  # Verify installation
  Set-Location $script_dir
  & $draco_encoder -i  "./draco/testdata/two_objects_inverse_materials.gltf" -o 'success.glb'
}

function AssertDracoInstallation() {
  if ($install -or !(Test-Path $draco_encoder)) {
    $res = Read-Host "
  Install Draco? (y/n)
  Requires:
  * Python: https://www.python.org/downloads/ 
  * C++ Build Tools: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
  * CMake: https://cmake.org/download/"
    if ($res.ToLower().Contains("y")) {
      if (AssertDependencies) {
        InstallDraco
        return $true
      }
    }
  }
  else {
    return $true
  }
  return $false
}
#endregion Install
function EnqueueModels {
  param([string]$folder)
  $q = New-Object System.Collections.Queue
  foreach ($file in Get-ChildItem -Path $folder | Where-Object { $_.extension -in ".gltf", ".glb" }) {
    $q.Enqueue($file.FullName)
  }
  foreach ($subfolder in Get-ChildItem -Path $folder -Directory) {
    EnqueueModels -folder $subfolder.FullName
  }
  return $q
}
function Encode([string]$source) {
  $target = $source -replace '\.gl(b|tf)$', '.drc'
  & $draco_encoder -i $source -o $target
  if ($target.Length -and (Test-Path -Path $target)) {
    $saved = (Get-Item $source).Length - (Get-Item $target).Length
    if ($saved -gt 0) {
      return $saved 
    }
  }
  return 0
}

function ProcessQueue {
  param([System.Collections.Queue]$q)
  $a = 0
  $b = 0
  while ($q.Count) {
    $source = $q.Dequeue()
    $res = Encode $source
    $savings = $res[$res.Count - 1]
    if ($savings -gt 0) {
      $a++
      $b += $savings
    }
  }
  return @($a, $b)
}
$testing = $false
$test_source_folder = './draco/testdata/'
if ($testing) {
  $source_folder = $test_source_folder
}

function Run {  
  if (AssertDracoInstallation) {
    $modelQueue = EnqueueModels($source_folder)
    $res = ProcessQueue($modelQueue)
    $fileCount = $res[0]
    $totalSaved = ($res[1] / (1024 * 1024)).ToString("F4")
    Write-Host "Saved $totalSaved MB across $fileCount files"
  }
}
Run