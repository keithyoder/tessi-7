import { Controller } from "@hotwired/stimulus"
import { Chart } from 'chart.js'

// Connects to data-controller="pie-chart"
export default class extends Controller {
  static values = {
    data: Object,
    title: String
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
    
    // Convert data object to labels and values arrays
    const labels = Object.keys(this.dataValue)
    const values = Object.values(this.dataValue)
    
    // Generate colors
    const colors = this.generateColors(labels.length)
    
    this.chart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: colors.background,
          borderColor: colors.border,
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 10,
              font: {
                size: 12
              }
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const label = context.label || ''
                const value = context.parsed || 0
                const total = context.dataset.data.reduce((a, b) => a + b, 0)
                const percentage = ((value / total) * 100).toFixed(1)
                return `${label}: ${value} (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }

  generateColors(count) {
    // Nice color palette
    const palette = [
      '#4e73df', // Blue
      '#1cc88a', // Green
      '#36b9cc', // Cyan
      '#f6c23e', // Yellow
      '#e74a3b', // Red
      '#858796', // Gray
      '#5a5c69', // Dark gray
      '#6610f2', // Purple
      '#fd7e14', // Orange
      '#20c9a6'  // Teal
    ]
    
    const background = []
    const border = []
    
    for (let i = 0; i < count; i++) {
      const color = palette[i % palette.length]
      background.push(color)
      border.push(color)
    }
    
    return { background, border }
  }
}