import { application } from "./application"

const context = require.context(".", true, /\.js$/)
context.keys().forEach((key) => {
  const controller = context(key).default
  const name = key
    .replace("./", "")
    .replace("_controller.js", "")
    .toLowerCase()
  application.register(name, controller)
})
