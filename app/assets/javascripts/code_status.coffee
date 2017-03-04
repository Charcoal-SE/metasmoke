# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  if location.pathname == '/status/code'
    $("#show-all-gem-versions").on "click", (e) ->
      e.preventDefault()

      $("table#gems-versions-table .minor").toggleClass 'hide'
      $(this).toggleClass 'shown'

    $("#toggle-compare-diff").click (e) ->
      e.preventDefault()
      $(this)
      $(this).toggleClass "shown"
             .parents "details"
             .find ".compare-diff"
             .toggleClass "hide"

    $("#toggle-commit-diff").click (e) ->
      e.preventDefault()
      $(this)
      $(this).toggleClass "shown"
             .parents "details"
             .find ".commit-diff"
             .toggleClass "hide"

    $.get "https://api.github.com/repos/Charcoal-SE/metasmoke", ({ default_branch }) ->
      $(".fill-branch")
        .text default_branch
        .attr "href", "https://github.com/Charcoal-SE/metasmoke/tree/#{default_branch}"
      $.get "https://api.github.com/repos/Charcoal-SE/metasmoke/compare/#{window.commitSHA}...#{default_branch}", (meta) ->
        status = []
        if meta.ahead_by > 0
          status.push "#{meta.ahead_by} commit#{"s" if meta.ahead_by != 1} behind"
        if meta.behind_by > 0
          status.push "#{meta.behind_by} commit#{"s" if meta.behind_by != 1} ahead of"
        if !status.length
          status.push "even with"
        $(".fill-status").text status.join ", "

        $.get {
          url: "https://api.github.com/repos/Charcoal-SE/metasmoke/compare/#{window.commitSHA}...#{default_branch}",
          headers: {
            Accept: "application/vnd.github.v3.diff"
          }
        }, renderDiff("compare")
      $.get {
        url: "https://api.github.com/repos/Charcoal-SE/metasmoke/commits/#{window.commitSHA}"
        headers: {
          Accept: "application/vnd.github.v3.diff"
        }
      }, renderDiff("commit")

renderDiff = (type) ->
  (diff) ->
    unless diff && typeof diff == 'string'
      $("#toggle-#{type}-diff").addClass "no-diff"
      return

    diff2htmlUi = new Diff2HtmlUI {
      diff
    }
    diff2htmlUi.draw ".#{type}-diff", {
      showFiles: true,
      matching: "words"
    }
    diff2htmlUi.highlightCode ".#{type}-diff"
    diff2htmlUi.fileListCloseable ".#{type}-diff", false
