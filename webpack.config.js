const path = require('path');
const NODE_ENV = process.env.NODE_ENV;

module.exports = {
  mode: NODE_ENV || 'development',
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'static'),
    filename: 'script.js'
  },
  module: {
    rules: [
      {
        test: /\.elm/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {
            optimize: NODE_ENV === 'production'
          }
        }
      }
    ]
  }
}
