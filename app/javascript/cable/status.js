import createDebug from 'debug';
import { route } from '../util';
import cable from './cable';

const debug = createDebug('ms:status');

const failoverElement = link => {
  return `<a class="text-danger"
    data-confirm="This will take effect at the next ping, within a minute. Sure?" rel="nofollow" data-method="post" href="${link}">
    Failover
  </a>`;
};

let statusSocket;
route('/status', () => {
  statusSocket = cable.subscriptions.create('StatusChannel', {
    received(data) {
      debug('received', data);

      const { id, ts_unix: tsUnix, ts_ago: tsAgo, ts_raw: tsRaw, location, is_standby: isStandby, active, failover_link: failoverLink } = data;
      if ([id, tsUnix, tsAgo, tsRaw, location].some(x => x === null || x === undefined)) {
        return;
      }

      const row = $(`.status-row[data-id=${id}]`);
      row.find('.location-cell').find('.location').text(location);

      const standByLabel = row.find('.location-cell').find('.label');
      if (isStandby) {
        standByLabel.show();
        const newLabelClass = `label-${active ? 'primary' : 'default'}`;
        standByLabel.removeClass((_, classNames) => (classNames.match(/label-\S+/) || []).join(' '));
        standByLabel.addClass(newLabelClass);
      }
      else {
        standByLabel.hide();
      }

      row.children('td').last().html(failoverLink ? failoverElement(failoverLink) : '');

      const pingCell = row.find('.ping-cell');
      pingCell.attr('data-livestamp', tsUnix).attr('title', tsRaw);
      pingCell.text(`${tsAgo} ago`);
    }
  });
}, () => {
  statusSocket.unsubscribe();
});
