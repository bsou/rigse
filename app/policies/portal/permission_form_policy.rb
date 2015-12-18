class Portal::PermissionFormPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      if user.has_role?('manager','admin','researcher')
        all
      elsif user.is_project_admin? || user.is_project_researcher?
        where = []
        params = {}
        if user.is_project_admin?
          where << "(project_id in (:admin_project_ids))"
          params[:admin_project_ids] = user.admin_for_projects.map { |p| p.id }
        end
        if user.is_project_researcher?
          where << "(project_id in (:researcher_project_ids))"
          params[:researcher_project_ids] = user.researcher_for_projects.map { |p| p.id }
        end
        scope.where([where.join(" OR "), params])
      else
        none
      end
    end
  end

  def index?
    manager_or_project_admin?
  end

  def update_forms?
    manager_or_project_admin?
  end

  def create?
    manager_or_project_admin?
  end

  def destroy?
    manager_or_project_admin?
  end
end