import { application } from "./application"

// Manually import each controller for esbuild
import FaturaController from "./fatura_controller"
import HelloController from "./hello_controller"
import MapController from "./map_controller"
import ConexaoController from "./conexao_controller"
import GeolocationController from "./geolocation_controller"

// Register controllers
application.register("fatura", FaturaController)
application.register("hello", HelloController)
application.register("map", MapController)
application.register("conexao", ConexaoController)
application.register("geolocation", GeolocationController)

window.Stimulus = application
