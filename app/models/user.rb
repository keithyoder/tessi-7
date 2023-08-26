# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  enum role: { admin: 0, tecnico_n1: 1, tecnico_n2: 2, financeiro_n1: 3, financeiro_n2: 4 }
end
