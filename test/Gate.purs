-- | Fast policy gate runner (make gate).
module Test.Gate where

import Prelude

import Effect (Effect)
import Test.Policy.GateSpec as GateSpec
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] GateSpec.gateSpec
