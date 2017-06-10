import { route } from '../util';

let flagLogs;
route('/flagging/logs', () => {
  flagLogs = App.cable.subscriptions.create('FlagLogsChannel', {
    received(data) {
      $('table#all-flag-logs tbody').prepend(data.row);
    }
  });
}, () => {
  flagLogs.unsubscribe();
  flagLogs = null;
});
