import createDebug from 'debug';
import { route } from '../util';
import cable from './cable';

const debug = createDebug('ms:status');

route('/status', () => {
  let statusSocket = cable.subscriptions.create('StatusChannel', {
    received(data) {
      debug('received', data);

      let {id, ts_unix, ts_ago, ts_raw, location} = data;
      if ([id, ts_unix, ts_ago, ts_raw, location].some(x => x === null || x === undefined)) {
        return;
      }

      let row = $(`.status-row[data-id=${id}]`);
      row.find('.location-cell').find('.location').text(location);

      let pingCell = row.find('.ping-cell');
      pingCell.attr('data-livestamp', ts_unix).attr('title', ts_raw);
      pingCell.text(`${ts_ago} ago`);
    }
  });
}, () => {
  statusSocket.unsubscribe();
});
