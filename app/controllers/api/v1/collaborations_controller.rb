class API::V1::CollaborationsController < API::APIController

  # POST api/v1/collaborations
  def create
    input = create_input
    return unauthorized unless create_auth(input)
    create_collaboration = API::V1::CreateCollaboration.new(input)
    result = create_collaboration.call
    if result
      render status: 201, json: result
    else
      error(create_collaboration.errors)
    end
  end

  # GET api/v1/collaborations/available_collaborators?offering_id=:id
  def available_collaborators
    input = available_collaborators_input
    return unauthorized unless available_collaborators_auth(input)
    clazz = Portal::Offering.find(input[:offering_id]).clazz
    render json: clazz.to_api_json[:students]
  end

  # GET api/v1/collaborations/:id/collaborators_endpoints
  def collaborators_endpoints
    input = collaborators_endpoints_input
    return unauthorized unless collaborators_endpoints_auth(input)
    show_endpoints = API::V1::ShowCollaboratorsEndpoints.new(input)
    result = show_endpoints.call
    if result
      return render json: result
    else
      error(show_endpoints.errors)
    end
  end

  private

  # Input handling

  def create_input
    result = params.permit(:offering_id, {students: [:id, :password]}, :external_activity)
    result[:owner_id] = current_visitor.portal_student && current_visitor.portal_student.id
    result
  end

  def available_collaborators_input
    {
      offering_id: params.require(:offering_id)
    }
  end

  def collaborators_endpoints_input
    {
      collaboration_id: params.require(:id),
      host_with_port: request.host_with_port
    }
  end

  # Authorization
  # TODO: move to separate class?

  def create_auth(input)
    class_member(input)
  end

  def available_collaborators_auth(input)
    class_member(input)
  end

  # FIXME: we need to be more strict about it, as this actions shows access tokens of other students!
  #        Only some special user should be allowed to show student endpoints.
  def collaborators_endpoints_auth(input)
    return false if current_user.nil?
    collaboration = Portal::Collaboration.find(input[:collaboration_id])
    collaboration.owner == current_user.portal_student
  end

  def class_member(input)
    return false if current_user.nil?
    offering = Portal::Offering.find(input[:offering_id])
    clazz = offering.clazz
    student = current_user.portal_student
    clazz.students.include?(student)
  end

end
