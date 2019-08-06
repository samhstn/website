const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin').CleanWebpackPlugin;
const CopyWebpackPlugin = require('copy-webpack-plugin');
const webpack = require('webpack');

module.exports = {
  mode: 'development',
  entry: [
    './src/index.js',
    'webpack-hot-middleware/client'
  ],
  output: {
    path: path.resolve(__dirname, 'static'),
    publicPath: '/static',
    filename: 'script.js'
  },
  module: {
    rules: [
      {
        test: /\.(html|css)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name].[ext]'
        }
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: 'elm-hot-webpack-loader'
          },
          {
            loader: 'elm-webpack-loader',
            options: {
              cwd: __dirname,
              forceWatch: true,
              debug: true
            }
          }
        ]
      }
    ]
  },
  plugins: [
    new CleanWebpackPlugin(),
    new CopyWebpackPlugin([{ from: 'assets/images', to: 'images' }]),
    new webpack.HotModuleReplacementPlugin()
    // new CopyWebpackPlugin([{ from: 'assets/images', to: 'images/[name]-[contenthash].[ext]' }])
  ]
}
