class ProfilesController < ApplicationController
  def show
    @profile = Profile.stored or redirect_to new_profile_path
  end

  def new
    @profile = Profile.new(contact: "comms")
  end

  def create
    save(Profile.new(profile_params), notice: "Profile created.", failure: :new)
  end

  def edit
    @profile = Profile.stored.dup.presence || redirect_to(new_profile_path)
  end

  def update
    save(Profile.new(profile_params), notice: "Profile updated.", failure: :edit)
  end

  private

  # 303 after success, 422 with the form re-rendered (and the errors) after failure: what Turbo expects
  def save(profile, notice:, failure:)
    @profile = profile
    if profile.valid?
      Profile.stored = profile
      redirect_to profile_path, status: :see_other, notice: notice
    else
      render failure, status: :unprocessable_entity
    end
  end

  def profile_params = params.require(:profile).permit(:callsign, :email, :bio, :role, :shields, :contact, :clearance, :birthday)
end
