import createDebug from 'debug';
import { route } from '../util';
import cable from './cable';

const debug = createDebug('ms:status');

let statusSocket;
route('/status', () => {
  statusSocket = cable.subscriptions.create('StatusChannel', {
    received(data) {
      debug('received', data);

      const { id, ts_unix: tsUnix, ts_ago: tsAgo, ts_raw: tsRaw, location } = data;
      if ([id, tsUnix, tsAgo, tsRaw, location].some(x => x === null || x === undefined)) {
        return;
      }

      const row = $(`.status-row[data-id=${id}]`);
      row.find('.location-cell').find('.location').text(location);

      const pingCell = row.find('.ping-cell');
      pingCell.attr('data-livestamp', tsUnix).attr('title', tsRaw);
      pingCell.text(`${tsAgo} ago`);
    }
  });
}, () => {
  statusSocket.unsubscribe();
});
