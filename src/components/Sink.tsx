import { useEffect, useState } from "react";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import * as THREE from "three";

const model = "/sink/4k/sink.drc";
const dracoPath = "https://www.gstatic.com/draco/versioned/decoders/1.5.7/";
const loader = new DRACOLoader();
loader.setDecoderPath(dracoPath);
/**
 * Throw this file away after you figure out how to use draco with fiber
 */
export function Sink(props) {
  const [sinkModel, setSinkModel] = useState(null);

  useEffect(() => {
    loader.load(model, function (geometry) {
      const material = new THREE.MeshStandardMaterial({ color: 0xa5a5a5 });
      const mesh = new THREE.Mesh(geometry, material);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      setSinkModel(mesh);
    });
  }, []);

  return (
    <group {...props} dispose={null}>
      {sinkModel && <primitive object={sinkModel} />}
    </group>
  );
}
