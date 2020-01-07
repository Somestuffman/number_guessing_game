defmodule Guesser.Server do
  require Integer

  def start(num, tries \\ 3) do
    guessed_num = :rand.uniform(num)

    spawn(__MODULE__, :play, [guessed_num, tries * 2])
    |> Process.register(:guesser_server)
  end

  def play(guessed_num, tries, player \\ 1) do
    receive do
      {guessed_num, receiver} ->
        send(receiver, {:game_over, "Player #{player} guessed number #{guessed_num}"})

      {_num, receiver} when Integer.is_even(player) and tries > 1 ->
        next_move(receiver, guessed_num, tries, 1)

      {_num, receiver} when tries > 1 ->
        next_move(receiver, guessed_num, tries, 2)

      {_num, receiver} ->
        send(receiver, {:game_over, "Game is over. I guessed #{guessed_num}."})

      _ ->
        "Wrong message" |> IO.inspect()
        play(guessed_num, tries, player)
    end
  end

  defp next_move(receiver, guessed_num, tries, player) do
    rest_tries = tries - 1
    send(receiver, {:next_move, "Wrong! You`ve got #{rest_tries} try(s). Player #{player} turn."})
    play(guessed_num, rest_tries, player)
  end
end

defmodule Guesser.Client do
  def play do
    {get_num(), get_tries()} |> start_game()
  end

  defp get_num do
    IO.gets("Input your number: ") |> Integer.parse()
  end

  defp get_tries do
    IO.gets("Input number of tries: ") |> Integer.parse()
  end

  defp start_game({{num, _}, {tries, _}})
       when is_integer(num) and is_integer(tries) and num > 0 and tries > 0 do
    Guesser.Server.start(num, tries)
    IO.puts("Try to guess number from 0 to #{num}!")
    make_move()
  end

  defp start_game(_) do
    IO.inspect("Please, input only integer numbers greater than 0!")
    play()
  end

  defp make_move do
    IO.gets("Input guessed number: ")
    |> Integer.parse()
    |> make_move()
  end

  defp make_move({num, _}) when is_integer(num) and num > 0 do
    send(:guesser_server, {num, self()})

    receive do
      {:next_move, msg} ->
        IO.puts(msg)
        make_move()

      {:game_over, msg} ->
        IO.puts(msg)

        IO.gets("Play again? (yes/no): ")
        |> String.trim()
        |> replay()
    after
      5000 ->
        IO.puts("No response :(")
    end
  end

  defp make_move(_) do
    IO.puts("Invalid number! Input only integers greater than 0!")
    make_move()
  end

  defp replay("yes"), do: play()
  defp replay(_), do: IO.puts("Thanks for playing! Bye!")
end
