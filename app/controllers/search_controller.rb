# frozen_string_literal: true

class SearchController < ApplicationController
  include ControllerWithCrossProjectAccessCheck
  include SearchHelper
  include RendersCommits

  SCOPE_PRELOAD_METHOD = {
    projects: :with_web_entity_associations,
    issues: :with_web_entity_associations
  }.freeze

  around_action :allow_gitaly_ref_name_caching

  skip_before_action :authenticate_user!
  requires_cross_project_access if: -> do
    search_term_present = params[:search].present? || params[:term].present?
    search_term_present && !params[:project_id].present?
  end

  layout 'search'

  def show
    @project = search_service.project
    @group = search_service.group

    return if params[:search].blank?

    return unless search_term_valid?

    @search_term = params[:search]

    @scope = search_service.scope
    @show_snippets = search_service.show_snippets?
    @search_results = search_service.search_results
    @search_objects = search_service.search_objects(preload_method)

    render_commits if @scope == 'commits'
    eager_load_user_status if @scope == 'users'

    increment_search_counters

    check_single_commit_result
  end

  def count
    params.require([:search, :scope])

    scope = search_service.scope
    count = search_service.search_results.formatted_count(scope)

    render json: { count: count }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def autocomplete
    term = params[:term]

    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      @project = nil unless can?(current_user, :read_project, @project)
    end

    @ref = params[:project_ref] if params[:project_ref].present?

    render json: search_autocomplete_opts(term).to_json
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def preload_method
    SCOPE_PRELOAD_METHOD[@scope.to_sym]
  end

  def search_term_valid?
    unless search_service.valid_query_length?
      flash[:alert] = t('errors.messages.search_chars_too_long', count: SearchService::SEARCH_CHAR_LIMIT)
      return false
    end

    unless search_service.valid_terms_count?
      flash[:alert] = t('errors.messages.search_terms_too_long', count: SearchService::SEARCH_TERM_LIMIT)
      return false
    end

    true
  end

  def render_commits
    @search_objects = prepare_commits_for_rendering(@search_objects)
  end

  def eager_load_user_status
    return if Feature.disabled?(:users_search, default_enabled: true)

    @search_objects = @search_objects.eager_load(:status) # rubocop:disable CodeReuse/ActiveRecord
  end

  def check_single_commit_result
    if @search_results.single_commit_result?
      only_commit = @search_results.objects('commits').first
      query = params[:search].strip.downcase
      found_by_commit_sha = Commit.valid_hash?(query) && only_commit.sha.start_with?(query)

      redirect_to project_commit_path(@project, only_commit) if found_by_commit_sha
    end
  end

  def increment_search_counters
    Gitlab::UsageDataCounters::SearchCounter.count(:all_searches)

    return if params[:nav_source] != 'navbar'

    Gitlab::UsageDataCounters::SearchCounter.count(:navbar_searches)
  end

  def append_info_to_payload(payload)
    super

    # Merging to :metadata will ensure these are logged as top level keys
    payload[:metadata] || {}
    payload[:metadata]['meta.search.group_id'] = params[:group_id]
    payload[:metadata]['meta.search.project_id'] = params[:project_id]
    payload[:metadata]['meta.search.search'] = params[:search]
    payload[:metadata]['meta.search.scope'] = params[:scope]
  end
end
