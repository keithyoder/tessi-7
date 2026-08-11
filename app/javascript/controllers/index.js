import { application } from "./application"

// Manually import each controller for esbuild
import BuscaController from "./busca_controller"
import ClipboardController from "./clipboard_controller"
import ConexaoController from "./conexao_controller"
import DiagnosticoController from "./diagnostico_controller"
import FaturaController from "./fatura_controller"
import FaturamentoChartController from "./faturamento_chart_controller"
import GeolocationController from "./geolocation_controller"
import HelloController from "./hello_controller"
import MapController from "./map_controller"
import OsController from "./os_controller"
import PieChartController from "./pie_chart_controller"

// Register controllers
application.register("busca", BuscaController)
application.register("clipboard", ClipboardController)
application.register("conexao", ConexaoController)
application.register("diagnostico", DiagnosticoController)
application.register("fatura", FaturaController)
application.register("faturamento-chart", FaturamentoChartController)
application.register("geolocation", GeolocationController)
application.register("hello", HelloController)
application.register("map", MapController)
application.register("os", OsController)
application.register("pie-chart", PieChartController)

window.Stimulus = application