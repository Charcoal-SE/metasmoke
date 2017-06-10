import { route } from '../util';
import cable from './cable';

let flagLogs;
route('/flagging/logs', () => {
  flagLogs = cable.subscriptions.create('FlagLogsChannel', {
    received(data) {
      $('table#all-flag-logs tbody').prepend(data.row);
    }
  });
}, () => {
  flagLogs.unsubscribe();
  flagLogs = null;
});
