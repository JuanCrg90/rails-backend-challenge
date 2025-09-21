class AppointmentsController < ApplicationController
  # POST /appointments
  # Params: client_id, provider_id, starts_at, ends_at
  def create
    appointment = Appointment.new(appointment_params)
    if appointment.save
      render json: appointment
    else
      render json: { errors: appointment.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /appointments/:id
  # Bonus: cancel an appointment instead of deleting
  def destroy
    appointment = Appointment.find(params[:id])
    appointment.soft_cancel!
    render json: appointment
  end

  private

  def appointment_params
    params.require(:appointment).permit(:client_id, :provider_id, :starts_at, :ends_at)
  end
end
