/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Core Colors
        background: 'var(--color-background)', // gray-50
        foreground: 'var(--color-foreground)', // gray-900
        border: 'var(--color-border)', // gray-200
        input: 'var(--color-input)', // white
        ring: 'var(--color-ring)', // teal-600
        
        // Card Colors
        card: {
          DEFAULT: 'var(--color-card)', // white
          foreground: 'var(--color-card-foreground)' // gray-900
        },
        
        // Popover Colors
        popover: {
          DEFAULT: 'var(--color-popover)', // white
          foreground: 'var(--color-popover-foreground)' // gray-900
        },
        
        // Muted Colors
        muted: {
          DEFAULT: 'var(--color-muted)', // gray-100
          foreground: 'var(--color-muted-foreground)' // gray-600
        },
        
        // Primary Colors
        primary: {
          DEFAULT: 'var(--color-primary)', // slate-900
          foreground: 'var(--color-primary-foreground)' // white
        },
        
        // Secondary Colors
        secondary: {
          DEFAULT: 'var(--color-secondary)', // teal-600
          foreground: 'var(--color-secondary-foreground)' // white
        },
        
        // Accent Colors
        accent: {
          DEFAULT: 'var(--color-accent)', // cyan-500
          foreground: 'var(--color-accent-foreground)' // white
        },
        
        // Status Colors
        success: {
          DEFAULT: 'var(--color-success)', // green-600
          foreground: 'var(--color-success-foreground)' // white
        },
        
        warning: {
          DEFAULT: 'var(--color-warning)', // yellow-600
          foreground: 'var(--color-warning-foreground)' // white
        },
        
        error: {
          DEFAULT: 'var(--color-error)', // red-600
          foreground: 'var(--color-error-foreground)' // white
        },
        
        destructive: {
          DEFAULT: 'var(--color-destructive)', // red-600
          foreground: 'var(--color-destructive-foreground)' // white
        },
        
        // Maritime Specific Colors
        'maritime-navy': 'var(--color-maritime-navy)', // slate-900
        'maritime-teal': 'var(--color-maritime-teal)', // teal-600
        'maritime-turquoise': 'var(--color-maritime-turquoise)', // cyan-500
        'maritime-surface': 'var(--color-maritime-surface)', // white
        
        // Text Colors
        'text-primary': 'var(--color-text-primary)', // gray-900
        'text-secondary': 'var(--color-text-secondary)' // gray-600
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
        data: ['JetBrains Mono', 'monospace']
      },
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
        '6xl': ['3.75rem', { lineHeight: '1' }]
      },
      borderRadius: {
        lg: '8px',
        md: '6px',
        sm: '4px'
      },
      boxShadow: {
        'maritime': '0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06)',
        'maritime-lg': '0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)',
        'maritime-xl': '0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.05)'
      },
      animation: {
        'fade-in': 'fadeIn 300ms ease-out',
        'slide-down': 'slideDown 200ms ease-out',
        'pulse-critical': 'pulseCritical 1s ease-in-out infinite'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideDown: {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        pulseCritical: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' }
        }
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem'
      },
      zIndex: {
        '60': '60',
        '70': '70',
        '80': '80',
        '90': '90',
        '100': '100'
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('tailwindcss-animate')
  ],
}