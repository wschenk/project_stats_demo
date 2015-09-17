class User < ActiveRecord::Base
  has_many :identities, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable
  def github
    identities.where( :provider => "github" ).first
  end

  def github_client
    @github_client ||= Octokit::Client.new(access_token: github.accesstoken, auto_paginate: true)
  end

end
