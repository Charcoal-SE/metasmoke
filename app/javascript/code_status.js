/* global Diff2HtmlUI */
import { route } from './util';

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
  $.get('/status/code.json', ({ repo, compare, compare_diff, commit, commit_diff }) => {
    const { default_branch: defaultBranch } = repo;
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
    $('.commit summary').text(message);
    $('.commit pre').text(other.join('\n\n'));
  });
});

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
