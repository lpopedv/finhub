if Mix.env() == :test, do: System.halt(0)

alias Core.User.Services.CreateUserService
alias Core.User.Commands.CreateUserCommand

full_name = "John Doe"
email = "user@email.com"
password = "pass123456"

%{
  full_name: full_name,
  email: email,
  password: password
}
|> CreateUserCommand.build!()
|> CreateUserService.execute()
