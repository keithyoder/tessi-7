import { application } from "./application"

// Manually import each controller for esbuild
import FaturaController from "./fatura_controller"
import HelloController from "./hello_controller"

// Register controllers
application.register("fatura", FaturaController)
application.register("hello", HelloController)