const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin').CleanWebpackPlugin;
const CopyWebpackPlugin = require('copy-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  mode: 'production',
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'static'),
    filename: 'script-[contenthash].js'
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name]-[contenthash].[ext]'
        }
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader',
        options: {
          optimize: true
        }
      }
    ]
  },
  plugins: [
    new CleanWebpackPlugin(),
    new CopyWebpackPlugin(
      [
        {
          from: 'assets/images',
          to: 'images/[name]-[contenthash].[ext]'
        }
      ]
    ),
    new HtmlWebpackPlugin({
      template: 'src/index.ejs',
      inject: false
    })
  ]
}
