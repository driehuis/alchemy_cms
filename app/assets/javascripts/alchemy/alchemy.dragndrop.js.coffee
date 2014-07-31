#= require jquery-ui/draggable
#= require jquery-ui/sortable
#
window.Alchemy = {} if typeof (window.Alchemy) is "undefined"

$.extend Alchemy,

  tinymceIDsFromDraggable: (ui) ->
    ids = []
    $textareas = ui.item.find('textarea.default_tinymce, textarea.custom_tinymce')
    $($textareas).each ->
      id = this.id.replace(/tinymce_/, '')
      ids.push parseInt(id, 10)
    ids

  SortableElements: (page_id, form_token, selector = '#element_area .sortable_cell') ->
    $(selector).sortable
      items: "div.element_editor"
      handle: ".element_handle"
      placeholder: "droppable_element_placeholder"
      forcePlaceholderSize: true
      dropOnEmpty: true
      opacity: 0.5
      cursor: "move"
      tolerance: "pointer"
      containment: "parent"
      update: (event, ui) ->
        ids = $.map $(this).children(), (child) ->
          $(child).attr "data-element-id"
        params_string = ""
        cell_id = $(this).attr("data-cell-id")
        # Is the trash window open?
        if Alchemy.TrashWindow.current
          # update the trash icon
          if $("#trash_items div.element_editor").not(".dragged").length is 0
            $("#element_trash_button .icon").removeClass "full"
        $(event.target).css "cursor", "progress"
        params_string = "page_id=" + page_id + "&authenticity_token=" + encodeURIComponent(form_token) + "&" + $.param(element_ids: ids)
        params_string += "&cell_id=" + cell_id  if cell_id
        $.ajax
          url: Alchemy.routes.order_admin_elements_path
          type: "POST"
          data: params_string
          complete: ->
            $(event.target).css "cursor", "auto"
            Alchemy.TrashWindow.refresh page_id
      start: (event, ui) ->
        ids = Alchemy.tinymceIDsFromDraggable(ui)
        Alchemy.Tinymce.remove(ids)
      stop: (event, ui) ->
        ids = Alchemy.tinymceIDsFromDraggable(ui)
        Alchemy.Tinymce.init(ids)

  SortableContents: (selector, token) ->
    $(selector).sortable
      items: ".content_editor"
      handle: "label"
      opacity: 0.5
      cursor: "move"
      tolerance: "pointer"
      containment: "parent"
      update: (event, ui) ->
        $this = $(this)
        ids = $.map $this.find('.content_editor'), (item) ->
          $(item).data('content-id')
        $.ajax
          url: Alchemy.routes.order_admin_contents_path
          type: "POST"
          data: "authenticity_token=" + encodeURIComponent(token) + "&" + $.param(content_ids: ids)
      start: (event, ui) ->
        ids = Alchemy.tinymceIDsFromDraggable(ui)
        Alchemy.Tinymce.remove(ids)
        ui.item.find('textarea.default_tinymce, textarea.custom_tinymce').css
          background: '#ededed'
          color: '#ededed'
          visibility: 'visible'
          height: 196
      stop: (event, ui) ->
        ids = Alchemy.tinymceIDsFromDraggable(ui)
        ui.item.find('textarea.default_tinymce, textarea.custom_tinymce').css
          background: '#fff'
          color: '#000'
          visibility: 'hidden'
          height: 140
        Alchemy.Tinymce.init(ids)

  SortablePictures: (selector, token) ->
    $(selector).sortable
      items: "div.dragable_picture"
      handle: "div.picture_handle"
      opacity: 0.5
      cursor: "move"
      tolerance: "pointer"
      containment: "parent"
      update: (event, ui) ->
        ids = $.map $(this).children("div.dragable_picture"), (child) ->
          child.id.replace /essence_picture_/, ""
        $(event.originalTarget).css "cursor", "progress"
        $.ajax
          url: Alchemy.routes.order_admin_contents_path
          type: "POST"
          data: "authenticity_token=" + encodeURIComponent(token) + "&" + $.param(content_ids: ids)
          complete: ->
            $(event.originalTarget).css "cursor", "move"

  DraggableTrashItems: (items_n_cells) ->
    $("#trash_items div.draggable").each ->
      cell_classes = ""
      cell_names = items_n_cells[@id]
      $.each cell_names, (i) ->
        cell_classes += "." + this + "_cell" + ", "
      $(this).draggable
        helper: "clone"
        iframeFix: "iframe#alchemy_preview_window"
        connectToSortable: cell_classes.replace(/,.$/, "")
        start: (event, ui) ->
          $(this).hide().addClass "dragged"
          ui.helper.css width: "300px"
        stop: ->
          $(this).show().removeClass "dragged"
