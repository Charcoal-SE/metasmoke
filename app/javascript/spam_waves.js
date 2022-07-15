import { route } from './util';

route(/^\/spam-waves/, () => {
  const forExpiry = $('[for="expiry"]');
  const expiryInput = $('#expiry');
  const existingButton = $('.expiry-in-48-hours-button');
  if (forExpiry.length > 0 && expiryInput.length > 0 && existingButton.length === 0) {
    const new48HoursButton = $('<button class="expiry-in-48-hours-button">in 48 hours</button>').on('click', event => {
      const newExpire = new Date(Date.now() + 48 * 60 * 60 * 1000);
      newExpire.setMilliseconds(0);
      expiryInput.val(newExpire.toISOString().replace('.000Z', '+00.0'));
      event.preventDefault();
    })
      .css({ marginLeft: '10px' });
    forExpiry.after(new48HoursButton);
    const valCriteriaList = ['title', 'body', 'username', 'max_user_rep'];
    const newSearchButton = $('<span class="search-button">(<a href="">Search</a>)</span>')
      .css({
        'font-size': '14px',
        'margin-left': '10px'
      });
    newSearchButton
      .find('a')
      .on('mousedown mouseover', function () {
        const criteriaInPage = valCriteriaList.map(key => [key, $(`#conditions_${key}${key.includes('rep') ? '' : '_regex'}`).val()]);
        const encodedCriteria = criteriaInPage.reduce((sum, [key, value]) => {
          if (key === 'max_user_rep') {
            return sum + `&user_rep_direction=%3C%3D&user_reputation=${value}`;
          } // Else
          // Convert the Unicode codepoint escapes from the format needed in spam waves to what's needed in search.
          value = value.replace(/\\u([\da-fA-F]{4})/g, '\\x{$1}');
          return sum + `&${key}_is_regex=1&${key}=${encodeURIComponent(value)}`;
        }, '');
        const sitesSelect = $('#sites');
        const selectionInnerUlLi = sitesSelect.closest('.bootstrap-select').find('.inner.open ul.inner > li');
        const selectedSiteLi = selectionInnerUlLi.filter('.selected');
        let siteParameter = '';
        let siteOptions = $();
        if (selectionInnerUlLi.length === 0) {
          // The select dropdown has not been opened, so we get the <option selected="selected">
          siteOptions = sitesSelect.find('option[selected="selected"]');
        }
        else if (selectedSiteLi.length === 1) {
          // The site dropdown has been opened and populated and there's only one site selected.
          // Search only supports a single site, so we don't try to handle converting multiple selections.
          const site = selectedSiteLi.text().trim();
          siteOptions = sitesSelect.find('option').filter(function () {
            return this.textContent.trim() === site;
          });
        }
        if (siteOptions.length === 1) {
          // Search only supports a single site
          siteParameter = `&site=${siteOptions.val()}`;
        }
        const url = `https://metasmoke.erwaysoftware.com/search?utf8=%E2%9C%93${encodedCriteria}${siteParameter}`;
        $(this).attr('href', url);
      });
    $('h3:contains("Conditions")').append(newSearchButton);
  }
  $('[type="datetime-local"]').attr('type', 'datetime');
});
