import { Controller } from "@hotwired/stimulus"
import { Chart } from 'chart.js'

// Connects to data-controller="faturamento-chart"
export default class extends Controller {
  static values = {
    data: Object
  }

  connect() {
    this.createChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  createChart() {
    const ctx = this.element.querySelector('canvas')
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.dataValue.Real.map(point => point[0]),
        datasets: [
          {
            label: 'Real',
            data: this.dataValue.Real.map(point => point[1]),
            borderColor: '#28a745',
            backgroundColor: 'rgba(40, 167, 69, 0.1)',
            borderWidth: 3,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0,
            fill: true
          },
          {
            label: 'Esperado',
            data: this.dataValue.Esperado.map(point => point[1]),
            borderColor: '#007bff',
            backgroundColor: 'rgba(0, 123, 255, 0.1)',
            borderWidth: 3,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0,
            fill: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.parsed.y.toLocaleString('pt-BR', {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2
                })
                return `${context.dataset.label}: R$ ${value}`
              }
            }
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Dia do Mês'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Valor Acumulado (R$)'
            },
            beginAtZero: true,
            ticks: {
              callback: (value) => {
                return 'R$ ' + value.toLocaleString('pt-BR', {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2
                })
              }
            }
          }
        }
      }
    })
  }
}