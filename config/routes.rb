Rails.application.routes.draw do
  
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Spotlight::Resources::Dri::Engine, at: 'spotlight_resources_dri'
  mount Blacklight::Oembed::Engine, at: 'oembed'
  mount Riiif::Engine => '/images', as: 'riiif'
  root to: 'spotlight/exhibits#index'

  concern :searchable, Blacklight::Routes::Searchable.new
  
    # this has to come before the Blacklight + Spotlight routes to avoid getting routed as
    # a document request.
    resources :exhibits, path: '/', only: [] do
      resource :catalog, only: [], as: 'catalog', controller: 'spotlight/catalog' do
      end

      resource :home, only: [], as: 'home', controller: 'spotlight/home_pages' do
      end
    end

    resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog'
    resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
      concerns :searchable
    end

    resource :search_across, only: [:index], path: '/search', controller: 'search_across' do
      concerns :searchable
    end

    concern :exportable, Blacklight::Routes::Exportable.new

    resources :exhibits, path: '/', only: [] do
      resource :bibliography_resources, only: [:create, :update]
      resource :viewers, only: [:create, :edit, :update]

      resources :solr_documents, only: [], path: '/catalog', controller: 'spotlight/catalog' do
        concerns :exportable

        member do
          get 'metadata' => 'metadata#show'
        end
      end
    end
  mount Spotlight::Engine, at: '/spotlight'
  mount Blacklight::Engine, at: '/'

  devise_for :users

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
