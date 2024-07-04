import { onLoad, route, addLocalSettingsPanel } from './util';

(() => {
  /* Generate post previews
   * Post previews are generated in JavaScript in order to not download images over the
   * network by default.  It also allows a more accurate generation of post contents under
   * most conditions.  However, given what SmokeDetector does with respect to pre-processing
   * the HTML prior to working with it and sending the HTML to metasmoke, there are some,
   * relatively rare, situations where it's impossible to recover the original HTML from
   * what's stored in metasmoke.
   */

  function addPostPreviews() {
    const previewPanels = $('.post-body-panel-preview > .panel > .panel-body:not(.javascript-generated)');
    previewPanels.html(''); // Wipe any existing content
    previewPanels.each(function () {
      const previewBody = $(this);
      const postSiteLink = previewBody.closest('.post-cell, .post-row, body .initial-content').find('.post-site-link');
      const tabsBodyContainer = previewBody.closest('.body-content-container');
      const reportedPostSDPreText = tabsBodyContainer.find('.post-body-panel-text .post-body-pre-block').text();
      const divWithPreview = generatePostBodyDivFromHtmlText(reportedPostSDPreText, false);
      pointRelativeURLsToSourceSESite(divWithPreview, { link: (postSiteLink[0] || { href: 'https://error--getting--site-link.foo/' }).href });
      // Hide images
      const hideImages = localStorage.hidePostPreviewImages !== 'false';
      divWithPreview.find('img').each(function () {
        const image = $(this);
        if (hideImages) {
          image
            .one('click', event => {
              image.attr('src', image.data('src'));
              event.preventDefault();
            });
        }
        else {
          image.attr('src', image.data('src'));
        }
      });
      // Add handlers for spoilers
      divWithPreview.find('blockquote.spoiler')
        .attr('data-spoiler', 'Reveal spoiler')
        .one('click', function () {
          $(this).addClass('is-visible');
        });
      previewBody
        .addClass('javascript-generated')
        .append(divWithPreview);
    });
  }

  onLoad(addPostPreviews);
  $(document).ajaxComplete(() => setTimeout(addPostPreviews, 10));
  $(window).on('MS-review-loaded', addPostPreviews);

  function addHideImagesLocalSetting() {
    const content = $(`<h3>Hide Images in Post Previews</h3>
    <div class="">
      <p>This will prevent both downloading and viewing of inappropriate images in post previews, unless you click to view each image. This is enabled by default.</p>
      <p>If enabled, the content of each image in a post preview will initially be a placeholder image. You will be able to click the placeholder image to display the original image. The original images will not be downloaded over the network unless the placeholder is clicked.</p>
      <p>If disabled, images in the post preview will always be displayed. They will automatically be downloaded whenever the post preview tab is available, even if the post preview is not displayed.</p>
      <input type="checkbox" name="hideImages" id="hideImages" checked="checked"> <label for="hideImages">Hide images in post preview panels initially with click to show image</label>
    </div>`);
    const hideImageInput = content.find('#hideImages');
    hideImageInput.on('change', () => {
      localStorage.hidePostPreviewImages = hideImageInput.is(':checked');
    });
    hideImageInput.prop('checked', localStorage.hidePostPreviewImages !== 'false');
    addLocalSettingsPanel(content);
  }

  route('/users/edit', addHideImagesLocalSetting);

  /* eslint-disable brace-style, capitalized-comments, comma-dangle, object-curly-spacing, arrow-parens */

  // The following code was copied from FIRE (https://github.com/Charcoal-SE/userscripts/blob/master/fire/fire.user.js)
  // by Makyen, the primary author for the copied code. It's under a dual Apache License 2.0 and MIT license.
  // The intent is for the code below and the code in FIRE to remain in sync.

  /**
   * toHTMLEntitiesBetweenTags - Convert HTML tags to  &lt;tag text&gt; that are within the start and end of a specified tag.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {string}    toChange                The complete text to make changes within.
   * @param   {string}    tagText                 The type of tag within which to make changes (e.g. "code")
   * @param   {RegExp}    whiteListedTagsRegex    Falsy or a RegExp that is used to match tags which should be whitelisted inside the changed area.
   *
   * @returns {string}                            The changed text
   */
  function toHTMLEntitiesBetweenTags(toChange, tagText, whiteListedTagsRegex) {
    let codeLevel = 0;
    const tagRegex = new RegExp(`(</?${tagText}>)`, 'g');
    const tagSplit = (toChange || '').split(tagRegex);
    const tagBegin = `<${tagText}>`;
    const tagEnd = `</${tagText}>`;
    return tagSplit.reduce((text, split) => {
      if (split === tagBegin) {
        codeLevel++;
        if (codeLevel === 1) {
          return text + split;
        }
      } else if (split === tagEnd) {
        codeLevel--;
      }
      if (codeLevel > 0) {
        split = split.replace(/</g, '&lt;').replace(/>/g, '&gt;');
        if (whiteListedTagsRegex) {
          whiteListedTagsRegex.lastIndex = 0;
          split = split.replace(whiteListedTagsRegex, '<$1>');
        }
      }
      return text + split;
    }, '');
  }

  // Many of the attributes permitted here are not permitted in Markdown for SE, but are delivered by SE in the HTML for the post body.
  //   SE adds the additional attributes.
  // For <a>, 'rel' is not permitted in Markdown, but is in SE's HTML.
  // The Comprehensive Formatting Test:
  //   https://chat.stackexchange.com/transcript/message/63128026#63128026
  //   https://metasmoke.erwaysoftware.com/posts/by-url?url=//meta.stackexchange.com/a/325826
  //   https://meta.stackexchange.com/a/325826
  const whitelistedTags = {
    withAttributes: {
      blockquote: ['class'], // 'data-spoiler'], // data-spoiler is used on SE sites, but isn't in the HTML delivered by SE.
      div: ['class', 'data-lang', 'data-hide', 'data-console', 'data-babel'],
      ol: ['start'],
      pre: ['class'],
      span: ['class', 'dir'],
      h1: ['id'],
      h2: ['id'],
      h3: ['id'],
      h4: ['id'],
      h5: ['id'],
      h6: ['id'],
    },
    specialCases: {
      a: {
        general: ['title', 'rel', 'alt', 'aria-label', 'aria-labelledby', 'data-onebox-id'],
        specificValues: {
          class: ['post-tag', 'post-tag required-tag', 'post-tag moderator-tag', 'onebox-link'], // example post with tags: https://chat.stackexchange.com/transcript/11540?m=54674140#54674140
          // rel probably has a limited set of values, but that really hasn't been explored, yet.
          // rel: ['tag'], // example post with tags: https://chat.stackexchange.com/transcript/11540?m=54674140#54674140
        },
        // href must be relative, protocol-relative, http, or https.
        // For <a>, SE only permits a limited subset of "href" values, so we can be more specific on these.
        regexText: {href: '(?:https?:)?//?[^" ]*'},
      },
      iframe: {
        // example: https://chat.stackexchange.com/transcript/11540?m=59301624#59301624
        general: ['width', 'height'],
        regexText: {src: 'https://(?:www\\.)?youtube\\.com/embed/[^" ]+'},
      },
      img: {
        ordered: ['src', 'width', 'height', 'alt', 'title'],
        isOptionallySelfClosing: true,
      },
      table: {specificValues: {class: ['s-table']}}, // example post with table: https://chat.stackoverflow.com/transcript/41570?m=51575339#51575339
      td: {specificValues: {style: ['text-align: right;', 'text-align: left;', 'text-align: center;']}}, // example post with td: https://chat.stackoverflow.com/transcript/41570?m=51575339#51575339
      th: {specificValues: {style: ['text-align: right;', 'text-align: left;', 'text-align: center;']}}, // example post with th: https://chat.stackoverflow.com/transcript/41570?m=51575339#51575339
    },
    optionallySelfClosingTagsWithNoAttributes: {
      br: [],
      hr: [],
    },
    withNoAttributes: {
      b: [],
      code: [],
      dd: [],
      del: [],
      dl: [],
      dt: [],
      em: [],
      i: [],
      kbd: [],
      li: [],
      p: [],
      s: [],
      strike: [],
      strong: [],
      sub: [],
      sup: [],
      tbody: [],
      thead: [],
      tr: [],
      ul: [],
    },
  };
  const whitelistedAttributesByTagType = Object.assign({},
    whitelistedTags.optionallySelfClosingTagsWithNoAttributes,
    whitelistedTags.withNoAttributes,
    whitelistedTags.withAttributes,
    whitelistedTags.specialCases);

  /*
    sortJqueryByDepth is modified from an answer to "jQuery traversing order - depth first" : https://stackoverflow.com/a/5756066
    Copyright 2011-04-22 16:27:08Z by alexl: https://stackoverflow.com/users/72562/alexl
    licensed under CC BY-SA 3.0
  */

  /**
   * sortJqueryByDepth - Sort the elements in a jQuery Object by depth, deepest first.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {jQuery}    input    The elements to sort
   *
   * @returns {jQuery}             New jQuery Object with the deepest elements first.
   */
  function sortJqueryByDepth(input) {
    const allElements = input.map(function () {
      return {length: $(this).parents().length, element: this};
    }).get();
    allElements.sort((a, b) => a.length - b.length);
    return $(allElements.map(({element}) => element));
  }

  /**
   * convertChildElementsWithNonWhitelistedAttributesToText - In place, convert to text all descendants of a container which have non-whitelisted attributes.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {jQuery}    container    The elements and their descendants to check.
   *
   */
  function convertChildElementsWithNonWhitelistedAttributesToText(container) {
    // Get all elements within a <div>
    // Given that we might change some of the elements into text, this will allow us to get them again, if that occurs.
    // This no longer assumes that the current location in the DOM of the elements in the input does not need to be maintained (i.e. they will be moved).
    container = $(container);

    /**
     * convertElements - In place, one pass of converting to text the descendants of a container which have non-whitelisted attributes.
     *
     * @private
     * @memberof module:fire
     *
     * @param   {jQuery}     elementsIn    The elements and their descendants to check.
     *
     * @returns {boolean}                  Flag indicating if any changes were made.
     */
    function convertElements(elementsIn) {
      let didChange = false;
      elementsIn.each(function () {
        const attrList = [...this.attributes].map((attrNode) => attrNode.name.toLowerCase());
        const nodeType = this.nodeName.toLowerCase();
        const nodeTypeAttrList = whitelistedAttributesByTagType[nodeType];
        let shouldReplaceThis = false;
        if (!Array.isArray(nodeTypeAttrList) && typeof nodeTypeAttrList === 'object' && nodeTypeAttrList !== null) {
          // This is a special case tag.
          // Remove attributes which can have general values.
          const nonGeneralAttrs = attrList.filter((attr) => !Array.isArray(nodeTypeAttrList.general) || !nodeTypeAttrList.general.includes(attr));
          // Remove any which are specific values, where the value matches one which is permitted.
          const nonSpecificAttrs = nonGeneralAttrs.filter((attr) => !nodeTypeAttrList.specificValues || !Array.isArray(nodeTypeAttrList.specificValues[attr]) || !nodeTypeAttrList.specificValues[attr].includes(this.attributes[attr].nodeValue));
          const remainingAttrs = nonSpecificAttrs.filter((attr) => !nodeTypeAttrList.regexText || typeof nodeTypeAttrList.regexText[attr] !== 'string' || !(new RegExp(`^${nodeTypeAttrList.regexText[attr]}$`)).test(this.attributes[attr].nodeValue));
          const remainingUnorderedAttrs = remainingAttrs.filter((attr) => !Array.isArray(nodeTypeAttrList.ordered) || !nodeTypeAttrList.ordered.includes(attr));
          const remainingOrderedAttrs = remainingAttrs.filter((attr) => Array.isArray(nodeTypeAttrList.ordered) && nodeTypeAttrList.ordered.includes(attr));
          let foundIndex = -1;
          const areOrderedAttrsInOrder = remainingOrderedAttrs.every((attr) => {
            const newFoundIndex = nodeTypeAttrList.ordered.indexOf(attr);
            const newFoundIndexIsHigher = foundIndex < newFoundIndex;
            foundIndex = newFoundIndex;
            return newFoundIndexIsHigher;
          });
          shouldReplaceThis = remainingUnorderedAttrs.length > 0 || !areOrderedAttrsInOrder;
        } else if (!Array.isArray(nodeTypeAttrList) || !attrList.every((attr) => nodeTypeAttrList.includes(attr))) {
          // This isn't a valid tag
          shouldReplaceThis = true;
        }
        if (shouldReplaceThis) {
          const newOuterHTML = this.outerHTML.replace('<', '&lt;').replace(/<(\/[a-z\d]+>)$/, '&lt;$1');
          this.outerHTML = newOuterHTML;
          didChange = true;
        }
      });
      return didChange;
    }
    let allChildren;
    // Repeatedly do the conversion, until nothing is changed.
    // This can still end up with the HTML parsed incorrectly, but shouldn't have any elements which are
    // not whitelisted, or which are whitelisted element that have attributes which are not whitelisted.
    do {
      // Get all the elements again, and re-run the conversion.
      allChildren = sortJqueryByDepth(container.find('*'));
    } while (convertElements(allChildren));
  }

  const whiteListedSETagsRegex = (function () {
    // https://regex101.com/r/90UJ2K/1
    // https://regex101.com/r/9I7r9O/1
    /* eslint-disable no-useless-escape */
    const selfClosingBasicTagsRegexText = `(?:${Object.keys(whitelistedTags.optionallySelfClosingTagsWithNoAttributes).join('|')})\\s*/?`;
    const basicTagsRegexText = `\/?(?:${Object.keys(whitelistedTags.withNoAttributes).join('|')})\\s*`;
    const complexTagsClosingRegexText = `\/(?:${Object.keys(whitelistedTags.withAttributes).join('|')})\\s*`;
    const complexTagsRegexText = `(?:${Object.entries(whitelistedTags.withAttributes)
      .map(([tag, attrs]) => `(?:${tag}\\b(?: +(?:${attrs.join('|')})="[^"<>]*")*)`) // syntax highlighting fodder: "
      .join('|')})\\s*`;
    const specialCaseTagsClosingRegexText = `\/(?:${Object.keys(whitelistedTags.specialCases).join('|')})\\s*`;
    /* eslint-enable no-useless-escape */
    const specialCaseTagsRegexText = `(?:${Object.entries(whitelistedTags.specialCases).map(([tag, obj]) => {
      const unordered = [];
      if (Array.isArray(obj.general)) {
        unordered.push(`(?:${(obj.general || []).join('|')})="[^"<>]*"`); // syntax highlighting fodder: "
      }
      if (obj.specificValues) {
        unordered.push(Object.entries(obj.specificValues)
          .map(([specificValueAttr, values]) => `${specificValueAttr}="(?:${values.join('|')})"`)
          .join('|'));
      }
      if (obj.regexText) {
        unordered.push(Object.entries(obj.regexText)
          .map(([regexTextAttr, regexText]) => `${regexTextAttr}="${regexText}"`)
          .join('|'));
      }
      let unorderedRegexText = '';
      if (unordered.length > 0) {
        unorderedRegexText = `(?:(?: +(?:${unordered.join('|')}))*)`;
      }
      let allAttrs = unorderedRegexText;
      let orderedRegexText = '';
      if (obj.ordered) {
        orderedRegexText = `(?:(?: +${obj.ordered.join(`="[^"<>]*")?${unorderedRegexText}(?: +`)}="[^"<>]*")?)`;
        allAttrs = unorderedRegexText + orderedRegexText + unorderedRegexText;
      }
      const attrRegexText = `(?:${tag}\\b${allAttrs}\\s*${obj.isOptionallySelfClosing ? '/?' : ''})`;
      return attrRegexText;
    })
      .join('|')})`;
    const fullRegexText = `&lt;(${[
      selfClosingBasicTagsRegexText,
      basicTagsRegexText,
      complexTagsClosingRegexText,
      complexTagsRegexText,
      specialCaseTagsClosingRegexText,
      specialCaseTagsRegexText,
    ].join('|')})&gt;`;
    return new RegExp(fullRegexText, 'gi');
  })();
  /* The whitelisted RegExp is currently:
    2023-03-10:(https://regex101.com/r/YCHmek/1)
      &lt;((?:br|hr)\s*\/?|\/?(?:b|code|dd|del|dl|dt|em|i|kbd|li|p|s|strike|strong|sub|sup|tbody|thead|tr|ul)\s*|\/(?:blockquote|div|ol|pre|span|h1|h2|h3|h4|h5|h6)\s*|(?:(?:blockquote\b(?: +(?:class)="[^"<>]*")*)|(?:div\b(?: +(?:class|data-lang|data-hide|data-console|data-babel)="[^"<>]*")*)|(?:ol\b(?: +(?:start)="[^"<>]*")*)|(?:pre\b(?: +(?:class)="[^"<>]*")*)|(?:span\b(?: +(?:class|dir)="[^"<>]*")*)|(?:h1\b(?: +(?:id)="[^"<>]*")*)|(?:h2\b(?: +(?:id)="[^"<>]*")*)|(?:h3\b(?: +(?:id)="[^"<>]*")*)|(?:h4\b(?: +(?:id)="[^"<>]*")*)|(?:h5\b(?: +(?:id)="[^"<>]*")*)|(?:h6\b(?: +(?:id)="[^"<>]*")*))\s*|\/(?:a|iframe|img|table|td|th)\s*|(?:(?:a\b(?:(?: +(?:(?:title|rel|alt|aria-label|aria-labelledby|data-onebox-id)="[^"<>]*"|class="(?:post-tag|post-tag required-tag|post-tag moderator-tag|onebox-link)"|href="(?:https?:)?\/\/?[^" ]*"))*)\s*)|(?:iframe\b(?:(?: +(?:(?:width|height)="[^"<>]*"|src="https:\/\/(?:www\.)?youtube\.com\/embed\/[^" ]+"))*)\s*)|(?:img\b(?:(?: +src="[^"<>]*")?(?: +width="[^"<>]*")?(?: +height="[^"<>]*")?(?: +alt="[^"<>]*")?(?: +title="[^"<>]*")?)\s*\/?)|(?:table\b(?:(?: +(?:class="(?:s-table)"))*)\s*)|(?:td\b(?:(?: +(?:style="(?:text-align: right;|text-align: left;|text-align: center;)"))*)\s*)|(?:th\b(?:(?: +(?:style="(?:text-align: right;|text-align: left;|text-align: center;)"))*)\s*)))&gt;
  */

  /**
   * getHtmlAsDOMWrappedInDiv - Generate a <div> containing the provided HTML text.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {string}          htmlText     The text to change into DOM nodes.
   *
   * @returns {DOM_node}                     <div> containing the DOM node representation of the HTML text.
   */
  function getHtmlAsDOMWrappedInDiv(htmlText) {
    // If we just use jQuery to convert the HTML text to DOM, then the images are fetched, which might look suspicious if network traffic
    //   is being monitored (e.g. in a work environment) and the image is NSFW. This avoids that happening until such time as the elements
    //   are placed in the page DOM. Prior to that happening, we change the URL for images, if the user hasn't selected not to do so.
    // This also prevents various code execution attack vectors which don't function when the new nodes are not elements created in
    //   the page DOM. However, such code *IS* executed if the newly created nodes are just placed in the page DOM, even after this.
    //   Thus, it's necessary for subsequent processing to remove those types of attack vectors.
    // The htmlText may be malformed, so we wrap it in a div after conversion to DOM nodes.
    const parser = new DOMParser();
    const htmlAsDOM = parser.parseFromString(htmlText, 'text/html');
    // The body here will often have multiple child nodes. We want everything wrapped in a div, so:
    const newDiv = htmlAsDOM.createElement('div');
    newDiv.append(...htmlAsDOM.body.childNodes);
    return newDiv;
  }

  /**
   * generatePostBodyDivFromHtmlText - Generate a <div> containing the HTML for a post body from HTML text.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {string}          htmlText     The text to change into HTML.
   * @param   {truthy/falsy}    isTrusted    Truthy if the text supplied is from SE (i.e. it's trusted / not pre-processed by SD).
   *
   * @returns {jQuery}                       <div> containing the body HTML.
   */
  function generatePostBodyDivFromHtmlText(htmlText, isTrusted) {
    // Just having the whitelisted tags active is good, but results in the possibility that we've enabled
    //   a tag within <code>.
    // div and pre can have class and other attributes for snippets.

    // SE normally provides HTML with <code> sections having <, >, and & (???) replaced by their HTML entities. The .body we get from MS has all HTML entities
    //   throughout the text (not just in <code> and <blockquote>) replaced with their Unicode characters
    //   This is done to facilitate regex matching within the post, particularly within <code>.
    //   With what SD has done to the text it's not, necessarily, possible to
    //   recover back to the actual content (e.g. what happens with Markdown like `<code>`: SE would send "<code>&lt;code&gt;</code>", but that gets converted
    //   to "<code><code></code>" by SD/MS. In addition, it's possible there were originally other pieces of text which were HTML entities that are now
    //   Unicode characters which are incorrectly interpreted as valid HTML tags, etc.
    //   So, ultimately, the conversion from the body stored on MS to HTML text which we do here is, at best, an approximation. However, it's considerably
    //   better than not trying to perform that conversion at all.
    /*
      `<code>` foobar `</code>`
      produces
      <code>&lt;code&gt;</code> foobar <code>&lt;/code&gt;</code>
      processed:
      <code><code></code> foobar <code></code></code>

      `<code></code> foobar <code></code>`
      produces
      <code>&lt;code&gt;&lt;/code&gt; foobar &lt;code&gt;&lt;/code&gt;</code>
      processed:
      <code><code></code> foobar <code></code></code>

          */
    // What we have in the MS provided body is that the <code> sections have had all of the &gt;, &lt; and ? &amp; ? changed to actual characters, rather than the
    //   HTML entities, which is what SE provides. So, in order to display it (or compare it to what SE provides), we need to convert all of those back to the
    //   HTML entities. If we don't, then what's displayed could be incorrect.
    // At this point, it's reasonably consistently formatted HTML, due to being processed from Markdown by SE.
    // On deleted posts where the MS data isn't available, d.body could be undefined.

    let processedBody = htmlText;
    if (!isTrusted) {
      // If we are converting HTML text received from SE, then we don't need to handle the HTML
      //   entities having been converted to Unicode characters. We can just use the HTML text directly.
      whiteListedSETagsRegex.lastIndex = 0;
      const bodyOnlyWhitelist = $('<div/>')
        .text(htmlText || '') // Escape everything. NOTE: Everything should be unescaped coming from SD/MS, but properly formatted if it's from SE.
        .html() // Get the escaped HTML, unescape whitelisted tags.
        .replace(whiteListedSETagsRegex, '<$1>');
      processedBody = toHTMLEntitiesBetweenTags(bodyOnlyWhitelist, 'code');
      processedBody = toHTMLEntitiesBetweenTags(processedBody, 'blockquote', whiteListedSETagsRegex);
    }
    // At this point, if we just pass the HTML to jQuery, then the images are fetched, which might look suspicious if network traffic is being monitored
    //   (e.g. in a work environment) and the image is NSFW. Still need to avoid that.
    // ProcessedBody may be malformed, so we don't wrap it in a div in HTML text.
    const containingDiv = getHtmlAsDOMWrappedInDiv(processedBody);
    if (!isTrusted) {
      convertChildElementsWithNonWhitelistedAttributesToText(containingDiv);
    }
    // Change all the image src prior to inserting into main document DOM or letting jQuery see it.
    // Not doing that here would result in the browser making fetches for each image's URL, which
    // could be bad for NSFW images in some situations (e.g. someone using this from work).
    // We could do this in the HTML text, but we want a DOM anyway, and it's easier to do it as DOM.
    containingDiv.querySelectorAll('img').forEach((image) => {
      image.dataset.src = image.src;
      image.src = 'https://via.placeholder.com/550x100//ffffff?text=Click+to+show+image.';
    });
    return $(containingDiv);
  }

  /**
   * pointRelativeURLsToSourceSESite - In place, change relative link URLs to point to the source SE site.
   *
   * @private
   * @memberof module:fire
   *
   * @param   {jQuery}    reportBody    jQuery Object containing the post body wrapped in a <div>.
   * @param   {object}    postData      The data for the post.
   */
  function pointRelativeURLsToSourceSESite(reportBody, postData) {
    // Convert relative URLs to point to the URL on the source site.
    // SE uses these for tags and some site-specific functionality (e.g. circuit simulation on Electronics)
    const [, siteHref] = (postData.link || '').match(/^((?:https?:)?\/\/(?:[a-z\d-]+\.)+[a-z\d-]+\/)/i) || ['', ''];
    // A couple of reports which had this problem:
    //   https://chat.stackexchange.com/transcript/11540?m=55601336#55601336  (links at bottom)
    //   https://chat.stackexchange.com/transcript/11540?m=54674140#54674140  (tags)
    reportBody.find('a').each(function () {
      const $this = $(this);
      let href = $this.attr('href') || '';
      if (!/^(?:[a-z]+:)?\/\//.test(href)) {
        // It's not a fully qualified or protocol-relative link.
        if (href.startsWith('/')) {
          // The path is absolute
          if (siteHref.endsWith('/')) {
            href = href.replace('/', '');
          }
          this.href = siteHref + href;
        } else {
          // It's relative to the question (really shouldn't see any of these)
          if (!siteHref.endsWith('/')) {
            href = `/${href}`;
          }
          this.href = postData.link + href;
        }
      }
    });
  }
  /* eslint-enable */
})();
