# frozen_string_literal: false

require 'spec_helper'

RSpec.describe AuthorNotesController, type: :controller do

  # TODO: auto-generated
  describe '#index' do
    it 'GET index' do
      get :index, {}, {}

      expect(response).to have_http_status(:ok)
    end
  end

  # TODO: auto-generated
  describe '#show' do
    it 'GET show' do
      get :show, id: 'a' * 36

      expect(response).to have_http_status(:ok)
    end
  end

  # TODO: auto-generated
  describe '#show_author_note' do
    it 'GET show_author_note' do
      get :show_author_note, {}, {}

      expect(response).to have_http_status(:ok)
    end
  end

  # TODO: auto-generated
  describe '#edit' do
    it 'GET edit' do
      get :edit, {}, {}

      expect(response).to have_http_status(:not_acceptable)
    end
  end

  # TODO: auto-generated
  describe '#update' do
    it 'PATCH update' do
      put :update, {}, {}

      expect(response).to have_http_status(:redirect)
    end
  end

  # TODO: auto-generated
  describe '#destroy' do
    it 'DELETE destroy' do
      delete :destroy, {}, {}

      expect(response).to have_http_status(:redirect)
    end
  end

end
