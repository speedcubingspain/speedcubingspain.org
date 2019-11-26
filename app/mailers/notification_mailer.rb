class NotificationMailer < ApplicationMailer
  def notify_new_subscriber
    @user = params[:user]
    mail(to: @user.email, subject: "[AES] Correo de bienvenida")
  end

  def notify_of_expiring_subscription
    @user = params[:user]
    mail(to: @user.email, subject: "[AES] Tu condición de socio está a punto de caducar")
  end

  def notify_of_new_competition
    @competition = params[:competition]
    mail(to: "notificaciones-socios@speedcubingspain.org", subject: "[AES] - #{@competition.name}", reply_to: "contacto@speedcubingspain.org")
  end

  def notify_team_of_failed_job
    @task_name = params[:task_name]
    @error = params[:error]
    mail(to: "administradores@speedcubingspain.org", subject: "[cron.aes][error] Una tarea ha fallado")
  end

  def notify_team_of_job_done
    @task_name = params[:task_name]
    @message = params[:message]
    mail(to: "administradores@speedcubingspain.org", subject: "[cron.aes][info] #{@task_name}")
  end
end
