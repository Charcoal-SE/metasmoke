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

    $.get "/status/code.json", ({ repo, compare, compare_diff, commit, commit_diff, commit_sha }) ->
      { default_branch } = repo
      $(".fill-branch")
        .text default_branch
        .attr "href", "https://github.com/Charcoal-SE/metasmoke/tree/#{default_branch}"

      status = []
      if compare.ahead_by > 0
        status.push "#{compare.ahead_by} commit#{"s" if compare.ahead_by != 1} behind"
      if compare.behind_by > 0
        status.push "#{compare.behind_by} commit#{"s" if compare.behind_by != 1} ahead of"
      if !status.length
        status.push "even with"
      $(".fill-status").text status.join ", "

      renderDiff("compare", compare_diff)
      renderDiff("commit", commit_diff)
      [message, other...] = commit.commit.message.split "\n\n"
      other = other.join "\n\n"
      $(".commit summary").text message
      $(".commit pre").text other

renderDiff = (type, diff) ->
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
