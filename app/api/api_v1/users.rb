class Users < Grape::API
  helpers SharedParams
  helpers WeiboHelper

  resources :users do
    desc "get user info"
    params do
      use :auth
      requires :user_id
    end
    get "/:user_id" do
      authenticate!

      user = User.find(params[:user_id])

      if user
        wrapper(user)
      else
        wrapper(false)
      end
    end

    ######

    desc "user's friends"
    params do
      use :auth
      requires :user_id
    end
    get ':user_id/friends' do
      authenticate!

      user = User.find(params[:user_id])

      if user
        weibo_account = user.weibo_account

        friends = if weibo_account.friends
          weibo_account.friends
        else
          result = weibo_friends(weibo_account.uid, weibo_account.token)
          weibo_account.friends = result['users'].map{|u| u['id']}
          weibo_account.save
          weibo_account.friends
        end

        a = Authentication.where(:uid.in => friends)

        if a
          users = a.map(&:user)
          hash = {}

          users.each do |user|
            hash[:friends] = user
            hash[:friends][:top_apps] = user.top_10_apps
          end

          wrapper(hash)
        else
          wrapper(false)
        end
      else
        wrapper(false)
      end
    end

    ######

    desc "upload apps"
    params do
      use :auth
    end
    post "apps" do
      authenticate!
      status(200)
    end
  end

  #####
  desc "user's apps"
  params do
    use :auth
    requires :user_id
  end
  get ":user_id/apps" do
    authenticate!
    user = User.find(params[:user_id])

    if user
      apps = user.apps
      wrapper(apps)
    else
      wrapper(false)
    end
  end
end