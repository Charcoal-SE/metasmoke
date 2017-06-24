// Note: You must restart bin/webpack-dev-server for changes to take effect

/* eslint global-require: 0 */
/* eslint import/no-dynamic-require: 0 */

const { basename, dirname, join, relative, resolve } = require('path');
const { sync } = require('glob');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const webpack = require('webpack');
const extname = require('path-complete-extname');
const { env, settings, output, loadersDir } = require('./configuration.js');

const extensionGlob = `**/*{${settings.extensions.join(',')}}*`;
const entryPath = join(settings.source_path, settings.source_entry_path);
const packPaths = sync(join(entryPath, extensionGlob));

module.exports = {
  entry: packPaths.reduce(
    (map, entry) => {
      const localMap = map;
      const namespace = relative(join(entryPath), dirname(entry));
      const key = join(namespace, basename(entry, extname(entry)));
      localMap[key] = [resolve(entry)];
      if (entry.includes('vendor')) {
        localMap[key].unshift('babel-polyfill');
      }
      return localMap;
    }, {}
  ),

  output: {
    filename: '[name].js',
    path: output.path,
    publicPath: output.publicPath
  },

  module: {
    rules: sync(join(loadersDir, '*.js')).map(loader => require(loader))
  },

  plugins: [
    new webpack.EnvironmentPlugin(JSON.parse(JSON.stringify(env))),
    new ExtractTextPlugin(env.NODE_ENV === 'production' ? '[name]-[hash].css' : '[name].css'),
    new ManifestPlugin({
      publicPath: output.publicPath,
      writeToFileEmit: true
    }),
    new webpack.ProvidePlugin({
      jQuery: 'jquery',
      $: 'jquery'
    })
  ],

  externals: {
    jquery: 'jQuery',
    moment: 'moment'
  },

  resolve: {
    extensions: settings.extensions,
    modules: [
      resolve(settings.source_path),
      'node_modules'
    ]
  },

  resolveLoader: {
    modules: ['node_modules']
  }
};
