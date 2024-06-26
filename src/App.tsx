import { CoffeePot, Environment } from "@components";
import { Canvas } from "@react-three/fiber";
import { useWindowSize } from "@uidotdev/usehooks";

export default function App() {
  const { width, height } = useWindowSize();

  return (
    <Canvas>
      <Environment>
        <CoffeePot />
      </Environment>
    </Canvas>
  );
}
