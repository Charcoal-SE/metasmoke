/* global Diff2HtmlUI */
import createDebug from 'debug';

import { route } from './util';

const debug = createDebug('ms:code_status');

route('/status/code', () => {
  $('#show-all-gem-versions').click(e => {
    e.preventDefault();
    $('table#gems-versions-table .minor').toggleClass('hide');
    $(this).toggleClass('shown');
  });
  $('#toggle-compare-diff').click(e => {
    e.preventDefault();
    $(this).toggleClass('shown')
           .parents('details')
           .find('.compare-diff')
           .toggleClass('hide');
  });
  $('#toggle-commit-diff').click(e => {
    e.preventDefault();
    $(this).toggleClass('shown')
           .parents('details')
           .find('.commit-diff')
           .toggleClass('hide');
  });
  $.get('/status/code.json', ({ repo: { default_branch: defaultBranch }, compare, compare_diff, commit, commit_diff }) => {
    $('.fill-branch')
      .text(defaultBranch)
      .attr('href', `https://github.com/Charcoal-SE/metasmoke/tree/${defaultBranch}`);

    const status = [];
    if (compare.ahead_by > 0) {
      status.push(`${compare.ahead_by} commit${compare.ahead_by === 1 ? '' : 's'} behind`);
    }
    if (compare.behind_by > 0) {
      status.push(`${compare.behind_by} commit${compare.behind_by === 1 ? '' : 's'} ahead of`);
    }
    if (status.length === 0) {
      status.push('even with');
    }
    $('.fill-status').text(status.join(', '));

    renderDiff('compare', compare_diff);
    renderDiff('commit', commit_diff);

    const [message, ...other] = commit.commit.message.split('\n\n');
    $('.commit summary').html(escapeAndLinkify(message));
    $('.commit pre').html(escapeAndLinkify(other.join('\n\n').trim()) || '<em>No details</em>');
  }).fail(debug);
});

const $escaper = $('<div>');
function escapeAndLinkify(message) {
  return $escaper
    .text(message)
    .html()
    .replace(/(^|\W)@([a-z0-9][a-z0-9-]*)(?!\/)(?=\.+[ \t\W]|\.+$|[^0-9a-zA-Z_.]|$)/ig, '$1<a class="user-mention" href="//github.com/$2">@$2</a>')
    .replace(/#(\d+)/g, '<a href="//github.com/Charcoal-SE/metasmoke/issues/$1">#$1</a>');
}

function renderDiff(type, diff) {
  if (!(diff && typeof diff === 'string')) {
    $(`#toggle-${type}-diff`).addClass('no-diff');
    return;
  }
  const diff2htmlUi = new Diff2HtmlUI({
    diff
  });
  diff2htmlUi.draw(`.${type}-diff`, {
    showFiles: true,
    matching: 'words'
  });
  diff2htmlUi.highlightCode(`.${type}-diff`);
  diff2htmlUi.fileListCloseable(`.${type}-diff`, false);
}
