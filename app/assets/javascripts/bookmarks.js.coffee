
InstanceCounter    = 0;
CollectionsDomID   = "bookmarks_box"
CollectionSelector = "##{CollectionsDomID}"
ItemSelector       = "#{CollectionSelector} .bookmark_item"
SortHandle         = "slide"
SortUrl            = "/bookmarks/sort"
EditUrl            = "/bookmarks/edit"

bookmark_identify = (div) ->
  div.readAttribute('data-bookmark-id');

class Bookmark
  constructor:(@div) ->
    @id          = bookmark_identify(@div)
    @editor      = @div.select('div.edit')[0]
    @edit_button = @div.select('a.edit')[0]
    @link_div    = @div.select('a.link_text')[0]
    @save_button = @div.select('button.save')[0]
    @name_field  = @div.select('input[name="name"]')[0]
    @url_field   = @div.select('input[name="url"]')[0]
    @name        = @div.readAttribute('data-bookmark-name')
    @url         = @div.readAttribute('data-bookmark-url')

    @editing     = false
    @save_button.observe 'click', (evt) =>
      @save()
    @edit_button.observe 'click', (evt) =>
      @edit()

  edit: ->
    if @editing
      @editor.hide()
      @editing = false
    else
      @editor.show()
      @editing = true

  update: (new_name,new_url) ->
    @name = new_name
    @url = new_url
    @link_div.update(@name)
    @link_div.writeAttribute('href',@url)
    @name_field.setValue(@name)
    @url_field.setValue(@url)

  save: ->
    @editing = false;
    new_name = @name_field.getValue()
    new_url  = @url_field.getValue()

    @editor.hide();
    new Ajax.Request EditUrl,
      method: 'post',
      parameters:
        id: @id
        name: new_name
        url: new_url
      requestHeaders:
        Accept: 'application/json'
      onSuccess: (transport) =>
        json = transport.responseText.evalJSON(true)
        @update(json.name, json.url)
      onFailure: (transport) =>
        @update(@name,@url)
        @div.highlight(startcolor: '#ff0000')


class BookmarksManager
  constructor: ->
    @bookmarks = {}
    Sortable.create CollectionsDomID,
      'tag'     : 'div'
      'handle'  : SortHandle
      'onUpdate': (divs) => @orderChanged(divs)
    @addBookmarks()

  addBookmarks: ->
    $$(ItemSelector).each (item) =>
      @bookmarkForDiv(item)

  bookmarkForDiv: (div) ->
    id = bookmark_identify(div)
    @bookmarks[id] || @addBookMark(div)

  addBookMark: (div) ->
    new Bookmark(div)

  orderChanged: (divs) ->
    results = $$(ItemSelector).map (div) =>
      @bookmarkForDiv(div).id
    @changeOrder(results)

  changeOrder:(array_of_ids) ->
    console.log(array_of_ids)
    new Ajax.Request SortUrl,
      method: 'post',
      parameters:
        ids: Object.toJSON(array_of_ids)
      requestHeaders:
        Accept: 'application/json'
      onSuccess: (transport) ->
        json = transport.responseText.evalJSON(true)
        console.log json




document.observe "dom:loaded", ->
  manager = new BookmarksManager()
