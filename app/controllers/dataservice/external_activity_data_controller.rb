class Dataservice::ExternalActivityDataController < ApplicationController

  private
  def can_create(learner)
    # allow admins and managers to re-post learner data
    # from LARA
    return true if (current_visitor.has_role? "admin")
    return true if (current_visitor.has_role? "manager")
    return true if (current_visitor == learner.user )
    raise ActionController::RoutingError.new('Not Allowed')
  end

  public
  def create
    learner_id = params[:id]
    if learner = Portal::Learner.find(learner_id)
      if can_create(learner) # If this fails we raise RoutingError('Not Allowed') (see above)
        # TODO: wrap this in a begin/rescue/end and return a real-ish error
        Delayed::Job.enqueue Dataservice::ProcessExternalActivityDataJob.new(learner_id, request.body.read)
        render :status => 201, :nothing => true and return
      end
    end
    raise ActionController::RoutingError.new('Not Found')
  end

end