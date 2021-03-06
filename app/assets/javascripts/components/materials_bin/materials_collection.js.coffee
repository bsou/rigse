{div, a} = React.DOM

window.MBMaterialsCollectionClass = React.createClass
  renderTeacherGuide: ->
    if Portal.currentUser.isTeacher and @props.teacherGuideUrl?
      (a {href: @props.teacherGuideUrl, target: '_blank'}, 'Teacher Guide')

  render: ->
    (div {className: 'mb-collection'},
      (div {className: 'mb-collection-name'}, @props.name)
      @renderTeacherGuide()
      for material in @props.materials or []
        (MBMaterial
          key: "#{material.class_name}#{material.id}"
          material: material
          archive: @props.archive
          assignToSpecificClass: @props.assignToSpecificClass
        )
    )

window.MBMaterialsCollection = React.createFactory MBMaterialsCollectionClass
