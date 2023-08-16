Rails.application.routes.draw do
  
  mount Spotlight::Resources::Dri::Engine, at: 'spotlight_resources_dri'
  mount Blacklight::Oembed::Engine, at: 'oembed'
  mount Riiif::Engine => '/images', as: 'riiif'
  root to: 'spotlight/exhibits#index'

  concern :searchable, Blacklight::Routes::Searchable.new
  
    # this has to come before the Blacklight + Spotlight routes to avoid getting routed as
    # a document request.
    resources :exhibits, path: '/', only: [] do
      resource :catalog, only: [], as: 'catalog', controller: 'spotlight/catalog' do
        #concerns :range_searchable
      end

      resource :home, only: [], as: 'home', controller: 'spotlight/home_pages' do
        #concerns :range_searchable
      end
    end

    resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog'
    resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
      concerns :searchable
      #concerns :range_searchable
    end

    resource :search_across, only: [:index], path: '/search', controller: 'search_across' do
      concerns :searchable
      #concerns :range_searchable
    end

    concern :exportable, Blacklight::Routes::Exportable.new

    resources :exhibits, path: '/', only: [] do
      resource :dor_harvester, controller: :"dor_harvester", only: [:create, :update] do
        resources :index_statuses, only: [:index, :show]
      end
      resource :bibliography_resources, only: [:create, :update]
      resource :viewers, only: [:create, :edit, :update]

      resources :solr_documents, only: [], path: '/catalog', controller: 'spotlight/catalog' do
        concerns :exportable

        member do
          get 'metadata' => 'metadata#show'
        end
      end
    end
  mount Spotlight::Engine, at: '/'
  mount Blacklight::Engine, at: '/'
#  root to: "catalog#index" # replaced by spotlight root path
 #   concern :searchable, Blacklight::Routes::Searchable.new

  #resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
  #  concerns :searchable
  #end

  devise_for :users
  #concern :exportable, Blacklight::Routes::Exportable.new

  #resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
  #  concerns :exportable
  #end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
