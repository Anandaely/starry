$ = require 'jquery'
Router = require 'router'
Handlebars = require 'hbsfy/runtime'
Upload = require '../../components/upload-image'
require '../../components/csrf'

# 组件
components =
  logo: require '../../templates/components/logo.hbs'
  profile: require '../../templates/components/profile.hbs'
  section: require '../../templates/components/section.hbs'
  sectionAdd: require '../../templates/components/section-add.hbs'
  sectionNavigation: require '../../templates/components/section-navigation.hbs'
  point: require '../../templates/components/point.hbs'
  pointEdit: require '../../templates/components/point-edit.hbs'

# 页面
pages =
  list: require '../../templates/pages/story/list.hbs'
  detail: require '../../templates/pages/story/detail.hbs'

Handlebars.registerPartial 'logo', components.logo
Handlebars.registerPartial 'profile', components.profile
Handlebars.registerPartial 'section', components.section
Handlebars.registerPartial 'section-add', components.sectionAdd
Handlebars.registerPartial 'section-navigation', components.sectionNavigation
Handlebars.registerPartial 'point', components.point
Handlebars.registerPartial 'point-edit', components.pointEdit

{upyun, preloaded} = adou

$ ->
  $wrap = $ '#wrap'
  $list = $ '#list'
  $detail = $ '#detail'

  _list = (data) ->
    $list.html pages.list data

    # 新建故事
    $('#add').on 'click', (event) ->
      event.preventDefault()
      $.ajax
        url: '/api/stories'
        type: 'POST'
        dataType: 'json'
      .done (story) ->
        router.setRoute "stories/#{story.id}"
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    $items = $ '#items'
    $items.on 'click', 'a .trash', (event) ->
      event.preventDefault()
      event.stopPropagation()
      $(this).closest('.actions').addClass('confirm').one 'mouseleave', -> $(this).removeClass 'confirm'

    $items.on 'click', 'a .cancel', (event) ->
      event.preventDefault()
      event.stopPropagation()
      $(this).closest('.actions').removeClass('confirm').unbind 'mouseleave'

    $items.on 'click', 'a .remove', (event) ->
      event.preventDefault()
      event.stopPropagation()
      $item = $(this).closest('a.item')
      $.ajax
        url: "/api/stories/#{$item.data('id')}"
        type: 'DELETE'
        dataType: 'json'
      .done ->
        $item.addClass('fadeOut').one $.support.transition.end, -> $item.remove()
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    $wrap.removeClass 'bige'

  _detail = (data) ->
    $detail.html pages.detail data

    {story} = data

    # 替换背景图
    $replaceBackground = $ '#replaceBackground'
    replaceBackgroundUpload = new Upload()
    replaceBackgroundUpload.assignBrowse $replaceBackground[0]
    replaceBackgroundUpload.on 'filesAdded', ->
      $replaceBackground.addClass 'loading'
    replaceBackgroundUpload.on 'filesSubmitted', (err) ->
      return window.alert err if err
      replaceBackgroundUpload.upload()
    replaceBackgroundUpload.on 'fileSuccess', (file, message) ->
      message = JSON.parse message
      image = upyun.buckets['starry-images'] + message.url
      $.ajax
        url: "/api/stories/#{story.id}"
        type: 'PATCH'
        data: background: image
        dataType: 'json'
      .done ->
        window.setTimeout ->
          $replaceBackground.removeClass 'loading'
          $replaceBackground.closest('.section-background').css 'backgroundImage', "url(#{image})"
        , 800
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    # 上传头像
    $profileImage = $ '#profileImage'
    profileImageUpload = new Upload()
    profileImageUpload.assignBrowse $profileImage[0]
    profileImageUpload.assignDrop $profileImage[0]
    profileImageUpload.on 'filesAdded', ->
      $profileImage.closest('.profile-image').addClass 'loading'
    profileImageUpload.on 'filesSubmitted', (err) ->
      return window.alert err if err
      profileImageUpload.upload()
    profileImageUpload.on 'fileSuccess', (file, message) ->
      message = JSON.parse message
      image = upyun.buckets['starry-images'] + message.url
      $.ajax
        url: "/api/stories/#{story.id}"
        type: 'PATCH'
        data: cover: image
        dataType: 'json'
      .done ->
        window.setTimeout ->
          $profileImage.removeClass('loading').addClass 'done'
          $profileImage.css 'backgroundImage', "url(#{image}!avatar)"
        , 800
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    # 主题
    $themes = $ '#themes'
    $('body').attr 'class', story.theme if story.theme

    $themes.on 'click', 'a', (event) ->
      event.preventDefault()
      theme = $(this).data 'color'
      $.ajax
        url: "/api/stories/#{story.id}"
        type: 'PATCH'
        data: theme: theme
        dataType: 'json'
      .done ->
        $('body').attr 'class', theme
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    # 简介
    $profile = $ '#profile'
    $profile.on 'click', '.profile .edit', (event) ->
      event.preventDefault()
      $profile.addClass 'edit'

    $profile.on 'click', '.profile-edit .cancel', (event) ->
      event.preventDefault()
      $profile.removeClass 'edit'

    $profile.on 'submit', '.profile-edit', (event) ->
      event.preventDefault()
      $form = $ this
      $submit = $form.find 'button[type="submit"]'
      $submit.button 'loading'
      $.ajax
        url: "/api/stories/#{story.id}"
        type: 'POST'
        data: $form.serialize()
        dataType: 'json'
      .done (story) ->
        $submit.button 'reset'
        $profile.html components.profile story
        $profile.removeClass 'edit'
      .fail (res) ->
        $submit.button 'reset'
        error = res.responseJSON.error
        window.alert error

    initSections = ->
      $detail.find('.section:even').addClass('section-black').next().removeClass 'section-black'

    initSections()

    # 新建片段
    $detail.on 'focus', '.section-add input', (event) ->
      event.preventDefault()
      $(this).closest('.input-group').addClass 'open'

    $detail.on 'blur', '.section-add input', (event) ->
      event.preventDefault()
      $(this).closest('.input-group').removeClass 'open'

    $detail.on 'submit', '.section-add', (event) ->
      event.preventDefault()
      $form = $ this
      $.ajax
        url: "/api/stories/#{story.id}/sections"
        type: 'POST'
        data: $form.serialize()
        dataType: 'json'
      .done (section) ->
        $form.find('input[name="name"]').val('').blur()
        $form.closest('.section').after components.section section
        initSections()
      .fail (res) ->
        error = res.responseJSON.error
        window.alert error

    $wrap.addClass 'bige'

  router = new Router()

  # 列表
  router.on '/stories\/?/?', ->
    if preloaded
      _list { stories: preloaded.stories }
      return preloaded = null

    $.ajax
      url: '/api/stories'
      type: 'GET'
      dataType: 'json'
    .done (res) ->
      _list { stories: res }
    .fail (res) ->
      error = res.responseJSON.error
      window.alert error

  # 详情
  router.on '/stories/:id', (id) ->
    if preloaded
      _detail { story: preloaded.story }
      return preloaded = null

    $.ajax
      url: "/api/stories/#{id}"
      type: 'GET'
      dataType: 'json'
    .done (res) ->
      _detail { story: res }
    .fail (res) ->
      error = res.responseJSON.error
      window.alert error

  router.configure html5history: true
  router.init()

  # 跳转
  $('body').on 'click', 'a.go', (event) ->
    event.preventDefault()
    router.setRoute $(event.currentTarget).attr 'href'

  # 退出登录
  $('body').on 'click', 'a.signout', (event) ->
    event.preventDefault()
    $.ajax
      url: '/api/signin'
      type: 'DELETE'
      dataType: 'json'
    .always ->
      window.location.href = '/'