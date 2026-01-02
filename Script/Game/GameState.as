class AJeffsGameState : AGameStateBase
{
	// 	Platform //
	UPROPERTY()
	APlacePlatforms PlacePlatforms;
	int platIndex = 0;
	// ------------------- //

	// 	UPROPERTIES	//
	UPROPERTY()
	UDataTable JeffsData;
	// ------------------- //

	// 	Jeffs //
	TArray<TSubclassOf<AJeff>> SelectedJeff;
	TArray<TSubclassOf<AJeff>> AllJeffs;
	TArray<AJeff> PlayerJeffs;
	TArray<AJeff> EnemyJeffs;
	TArray<AJeff> EnemyActionQueue;
	TArray<TSubclassOf<AJeff>> JefftoSpawn;
	// ------------------- //

	// 	Other Arrays //
	TArray<APlatform> PlatformsEnemies;
	TArray<APlatform> PlatformsPlayer;
	// ------------------- //

	// 	GAME AND TURNS //
	bool bJeffAlreadyKilled;
	int32 PlayerMoves = 3;
	bool bisPlayerTurn = true;
	bool GameStart = false;
	bool GamePaused = true;
	bool PendingIsMove = false;
	FIntPoint PendingMove;
	AJeff PendingEnemy;
	AJeff PendingTarget;
	int32 PPoints = 6;
	int32 EPoints = 6;
	// ------------------- //

	// 	WIDGETS / HUD //
	bool isSelectOpen = false;
	bool isSettingsOpen = false;
	bool isMenuOpen = false;
	bool isEndingOpen = false;
	// ------------------- //

	// 	SETTINGS //
	bool isCameraFix = true;
	// ------------------- //

	// 	SETTINGS //
	// ------------------- //

// 	SPAWN PLAYERSJEFF AND ENEMIES 	//
	void SpawningJeff(FJeffsData Data)
	{
		if (PPoints >= 2)
		{
			auto pc = GetWorld().GameInstance.GetFirstLocalPlayerController();
			AGameController gc = Cast<AGameController>(pc);
			if (PlacePlatforms == nullptr || PlacePlatforms.PlatformsPlayer.Num() == 0)
				return;

			if (platIndex >= PlacePlatforms.PlatformsPlayer.Num())
				platIndex = 0;

			APlatform spawnPlatform = PlacePlatforms.PlatformsPlayer[platIndex];

			if (Data.AActorToSpawn == nullptr)
				return;

			AJeff spawnedJeff = Cast<AJeff>(SpawnActor(Data.AActorToSpawn));

			if (spawnedJeff == nullptr)
				return;

			FVector spawnLoc = spawnPlatform.GetActorLocation() + FVector(0, 0, 200);
			spawnedJeff.SetActorLocation(spawnLoc);
			spawnedJeff.SetActorRotation(FRotator(0, 0, 0));

			spawnedJeff.InitializeFromData(Data);

			spawnedJeff.PlatformNow = spawnPlatform;
			spawnedJeff.PlacePlatforms = PlacePlatforms;
			spawnedJeff.Team = EJeffTeam::Player;
			spawnedJeff.JeffCreateCard(spawnedJeff);
			PlayerJeffs.Add(spawnedJeff);
			platIndex++;
			if (spawnedJeff.TypeJeff == EJeffsType::Bezos)
			{
				ApplySupportPlayer();
			}
			PPoints -= 2;
			gc.MainHUD.MainWidget.ChangePoints(PPoints);
		}
	}

	void SpawnEnemiesJeffs(bool bInitialSpawn)
	{
		if (PlacePlatforms == nullptr || PlacePlatforms.PlatformsEnemies.Num() == 0)
			return;
		if (JeffsData == nullptr)
			return;

		TArray<FJeffsData> AllDataJeffs;
		TArray<FName> RowNames = JeffsData.GetRowNames();

		for (FName RowName : RowNames)
		{
			FJeffsData Data;
			if (JeffsData.FindRow(RowName, Data))
			{
				AllDataJeffs.Insert(Data);
			}
		}

		if (AllDataJeffs.Num() == 0)
			return;

		int NumJeffs = (bInitialSpawn) ? Math::Min(3, AllDataJeffs.Num()) : 1;
		TArray<int> SelectedIndices;

		while (SelectedIndices.Num() < NumJeffs)
		{
			int RandIndex = Math::RandRange(0, AllDataJeffs.Num() - 1);
			if (!SelectedIndices.Contains(RandIndex))
				SelectedIndices.Insert(RandIndex);
		}

		int platEIndex = 0;

		for (int i = 0; i < SelectedIndices.Num(); i++)
		{
			FJeffsData Data = AllDataJeffs[SelectedIndices[i]];

			if (platEIndex >= PlacePlatforms.PlatformsEnemies.Num())
				platEIndex = 0;

			APlatform spawnPlatform = PlacePlatforms.PlatformsEnemies[platEIndex];

			if (Data.AActorToSpawn == nullptr)
			{
				platEIndex++;
				continue;
			}

			AJeff spawnedJeff = Cast<AJeff>(SpawnActor(Data.AActorToSpawn));
			if (spawnedJeff == nullptr)
			{
				platEIndex++;
				continue;
			}

			FVector spawnLoc = spawnPlatform.GetActorLocation() + FVector(0, 0, 200);
			spawnedJeff.SetActorLocation(spawnLoc);
			spawnedJeff.SetActorRotation(FRotator(0, 180, 0));

			spawnedJeff.InitializeFromData(Data);

			spawnedJeff.PlatformNow = spawnPlatform;
			spawnedJeff.PlacePlatforms = PlacePlatforms;
			spawnedJeff.Team = EJeffTeam::Enemy;
			spawnedJeff.JeffCreateCard(spawnedJeff);
			EnemyJeffs.Add(spawnedJeff);
			platEIndex++;
			if (spawnedJeff.TypeJeff == EJeffsType::Bezos)
			{
				ApplySupportEnemy();
			}
			EPoints -= 2;
		}
	}
// ------------------- //

// 	MOVES AND TURNS	//
	// 	PLAYER	//
	UFUNCTION()
	void PlayerTurn()
	{
		APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();
		AGameController gc = Cast<AGameController>(pc);
		AMainHUD MainHUD = gc.MainHUD;
		if (MainHUD != nullptr)
		{
			MainHUD.MainWidget.UpdateMoves(PlayerMoves);
		}
		if (PlayerMoves == 0)
		{
			bisPlayerTurn = false;
			for (AJeff je : EnemyJeffs)
			{
				je.jeffUsed = false;
			}
			EnemyTurn();
		}
	}
	// ------------------- //

	// 	ENEMY HAS MOVES	//
	UFUNCTION()
	void EnemyTurn()
	{
		bJeffAlreadyKilled = false;
		if (bisPlayerTurn == true)
			return;
		PlayerMoves = 0;

		APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();
		AGameController gc = Cast<AGameController>(pc);
		AMainHUD MainHUD = gc.MainHUD;

		if (MainHUD != nullptr)
		{
			MainHUD.MainWidget.UpdateMoves(PlayerMoves);
		}

		if (EPoints >= 1)
		{
			SpawnEnemiesJeffs(false);
		}

		TArray<AJeff> JeffToMove;
		for (AJeff je : EnemyJeffs)
		{
			if (!je.jeffUsed && je != nullptr && je.PlatformNow != nullptr)
			{
				JeffToMove.Add(je);
			}
		}

		if (PlayerJeffs.Num() == 0)
		{

			isSelectOpen = false;
			isEndingOpen = true;

			if (MainHUD != nullptr)
			{
				MainHUD.JeffEndingWidget.bPlayerWon = false;
				MainHUD.ChangeMenu();
			}

			return;
		}

		if (JeffToMove.Num() == 0)
		{
			bisPlayerTurn = true;
			PlayerTurn();
			return;
		}

		EnemyActionQueue.Append(JeffToMove);
		ProccessNextEnemyAction();
	}
	// ------------------- //

	// 	JEFF ONE BY ONE //
	UFUNCTION()
	void ProccessNextEnemyAction()
	{
		if (EnemyActionQueue.Num() == 0)
		{
			bisPlayerTurn = true;
			PlayerTurn();
			return;
		}

		AJeff currentEnemy = EnemyActionQueue[0];
		EnemyActionQueue.RemoveAt(0);

		PerformEnemyAction(currentEnemy);

		System::SetTimer(this, n"ProccessNextEnemyAction", 1.0f, false);
	}
	// ------------------- //

	// 	GET ENEMY ACTION/ /
	void PerformEnemyAction(AJeff enemy)
	{
		PendingEnemy = enemy;
		AJeff target = nullptr;
		AJeff healtarget = nullptr;

		// GET HEAL
		if (enemy.TypeJeff == EJeffsType::Playero)
		{
			for (FIntPoint hl : enemy.GetShield())
			{
				for (AJeff e : EnemyJeffs)
				{
					if (e.PlatformNow.GridX == hl.X && e.PlatformNow.GridY == hl.Y && e.Vida <= e.MaxVida)
					{
						healtarget = e;
						break;
					}
				}
				if (healtarget != nullptr)
					break;
			}
		}

		// DO SHIELD
		if (enemy.TypeJeff == EJeffsType::Calabaza)
		{
			TArray<FIntPoint> possibleMoves;
			for (FIntPoint shld : enemy.GetShield())
			{
				int targetX = enemy.PlatformNow.GridX - shld.X;
				int targetY = enemy.PlatformNow.GridY - shld.Y;

				for (AJeff e : EnemyJeffs)
				{
					if (e.PlatformNow.GridX != targetX && e.PlatformNow.GridY != targetY)
					{
						for (FIntPoint move : enemy.GetMovements())
						{

							int newX = enemy.PlatformNow.GridX - move.X;
							int newY = enemy.PlatformNow.GridY - move.Y;

							if (move.Y <= enemy.PlatformNow.GridY)
							{
								bool yMovePossible = false;
								for (APlatform p : PlacePlatforms.PlatformsEnemies)
								{
									if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
									{
										possibleMoves.Add(move);
										yMovePossible = true;
										break;
									}
								}

								if (!yMovePossible)
								{
									for (APlatform p : PlacePlatforms.PlatformsEnemies)
									{
										if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
										{
											possibleMoves.Add(move);
											break;
										}
									}
								}
							}
							else
							{
								for (APlatform p : PlacePlatforms.PlatformsEnemies)
								{
									if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
									{
										possibleMoves.Add(move);
										break;
									}
								}
							}
						}
					}
				}
			}

			if (possibleMoves.Num() > 0)
			{
				int moveIndex = Math::RandRange(0, possibleMoves.Num() - 1);
				FIntPoint move = possibleMoves[moveIndex];
				PendingMove = move;
				PendingIsMove = true;

				int newX = PendingEnemy.PlatformNow.GridX - move.X;
				int newY = PendingEnemy.PlatformNow.GridX - move.Y;

				for (APlatform p : PlacePlatforms.PlatformsEnemies)
				{
					if (p.GridX == newX && p.GridY == newY)
						p.ChangeColor(EPlatformType::Movement);
					PendingEnemy.PlatformNow.ChangeColor(EPlatformType::Movement);
				}
			}
		}

		// GET ATTACKS
		for (FIntPoint atk : enemy.GetAttacks())
		{
			int targetX = enemy.PlatformNow.GridX - atk.X;
			int targetY = enemy.PlatformNow.GridY - atk.Y;

			for (AJeff p : PlayerJeffs)
			{
				if (p.PlatformNow.GridX == targetX && p.PlatformNow.GridY == targetY)
				{
					target = p;
					break;
				}
			}

			if (target != nullptr)
				break;
		}

		// DO ATTACK
		if (healtarget != nullptr)
		{

			PendingTarget = healtarget;
			PendingIsMove = false;

			for (APlatform p : PlacePlatforms.PlatformsEnemies)
			{
				if (p.GridX == target.PlatformNow.GridX && p.GridY == target.PlatformNow.GridY)
					p.ChangeColor(EPlatformType::Healing);
				PendingEnemy.PlatformNow.ChangeColor(EPlatformType::Healing);
			}
		}

		else if (target != nullptr)
		{
			PendingTarget = target;
			PendingIsMove = false;

			for (APlatform p : PlacePlatforms.PlatformsPlayer)
			{
				if (p.GridX == target.PlatformNow.GridX && p.GridY == target.PlatformNow.GridY)
					p.ChangeColor(EPlatformType::Attack);
				PendingEnemy.PlatformNow.ChangeColor(EPlatformType::Attack);
			}
		}

		// DO MOVE
		else
		{
			TArray<FIntPoint> possibleMoves;
			for (FIntPoint move : enemy.GetMovements())
			{

				int newX = enemy.PlatformNow.GridX - move.X;
				int newY = enemy.PlatformNow.GridY - move.Y;

				if (move.Y >= enemy.PlatformNow.GridY)
				{
					bool yMovePossible = false;
					for (APlatform p : PlacePlatforms.PlatformsEnemies)
					{
						if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
						{
							possibleMoves.Add(move);
							yMovePossible = true;
							break;
						}
					}

					if (!yMovePossible)
					{
						for (APlatform p : PlacePlatforms.PlatformsEnemies)
						{
							if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
							{
								possibleMoves.Add(move);
								break;
							}
						}
					}
				}
				else
				{
					for (APlatform p : PlacePlatforms.PlatformsEnemies)
					{
						if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
						{
							possibleMoves.Add(move);
							break;
						}
					}
				}
			}

			if (possibleMoves.Num() == 0)
			{
				for (APlatform p : PlacePlatforms.PlatformsEnemies)
				{
					if (IsPlatformOccupied(p) == nullptr)
					{
						FIntPoint move;
						move.X = enemy.PlatformNow.GridX - p.GridX;
						move.Y = enemy.PlatformNow.GridY - p.GridY;

						possibleMoves.Add(move);
						break;
					}
				}
			}

			int moveIndex = Math::RandRange(0, possibleMoves.Num() - 1);
			FIntPoint move = possibleMoves[moveIndex];
			enemy = PendingEnemy;
			PendingMove = move;
			PendingIsMove = true;
			int newX = PendingEnemy.PlatformNow.GridX - move.X;
			int newY = PendingEnemy.PlatformNow.GridY - move.Y;
			for (APlatform p : PlacePlatforms.PlatformsEnemies)
			{
				if (p.GridX == newX && p.GridY == newY)
					p.ChangeColor(EPlatformType::Movement);
				PendingEnemy.PlatformNow.ChangeColor(EPlatformType::Movement);
			}
		}

		System::SetTimer(this, n"DoEnemyAction", 1.0f, false);
	}
	// ------------------- //

	// DO ENEMY ACTION	//
	UFUNCTION()
	void DoEnemyAction()
	{
		if (PendingEnemy == nullptr)
		{
			bisPlayerTurn = true;
			PlayerTurn();
			for (APlatform p : PlacePlatforms.PlatformsPlayer)
				p.ChangeColor(EPlatformType::Base);
			for (APlatform p : PlacePlatforms.PlatformsEnemies)
				p.ChangeColor(EPlatformType::Enemy);
			return;
		}

		if (PendingEnemy.PlatformNow == nullptr)
		{
			Print("Pending Enemy PlatformNow is nullptr");
			bisPlayerTurn = true;
			PlayerTurn();
			for (APlatform p : PlacePlatforms.PlatformsPlayer)
				p.ChangeColor(EPlatformType::Base);
			for (APlatform p : PlacePlatforms.PlatformsEnemies)
				p.ChangeColor(EPlatformType::Enemy);
			return;
		}

		if (PendingIsMove)
		{
			int newX = PendingEnemy.PlatformNow.GridX - PendingMove.X;
			int newY = PendingEnemy.PlatformNow.GridY - PendingMove.Y;

			for (APlatform p : PlacePlatforms.PlatformsEnemies)
			{
				if (p.GridX == newX && p.GridY == newY && IsPlatformOccupied(p) == nullptr)
				{
					PendingEnemy.PlatformNow = p;
					PendingEnemy.SetActorLocation(FVector(p.GetActorLocation().X, p.GetActorLocation().Y, PendingEnemy.GetActorLocation().Z));
					break;
				}
			}
		}

		else if (PendingTarget != nullptr)
		{
			PendingTarget.Vida -= PendingEnemy.Ataque;
			PendingEnemy.DealDamage(PendingTarget);
		}

		for (APlatform p : PlacePlatforms.PlatformsPlayer)
			p.ChangeColor(EPlatformType::Base);
		for (APlatform p : PlacePlatforms.PlatformsEnemies)
			p.ChangeColor(EPlatformType::Enemy);
		PendingEnemy.PlatformNow.ChangeColor(EPlatformType::Enemy);

		PendingEnemy = nullptr;
		PendingTarget = nullptr;
		PendingIsMove = false;
		PendingMove = FIntPoint();

		bisPlayerTurn = true;
		if (PlayerJeffs.Num() < 3)
		{
			PlayerMoves = PlayerJeffs.Num();
		}
		else
		{
			PlayerMoves = 3;
		}
		for (AJeff jeff : PlayerJeffs)
		{
			jeff.jeffUsed = false;
		}
		bJeffAlreadyKilled = false;
		PlayerTurn();
	}
// ------------------- //

	// 	FUNCTIONS 	//
	AJeff IsPlatformOccupied(APlatform Platform)
	{

		TArray<AJeff> jAllJeffs;
		GetAllActorsOfClass(jAllJeffs);
		for (AJeff j : jAllJeffs)
		{
			if (j.PlatformNow == Platform)
				return j;
		}
		return nullptr;
	}

	AJeff GetJeffAtGrid(int x, int y)
	{
		for (AJeff jeff : PlayerJeffs)
		{
			if (jeff.PlatformNow != nullptr && jeff.PlatformNow.GridX == x && jeff.PlatformNow.GridY == y)
			{
				return jeff;
			}
		}
		return nullptr;
	}

	void ApplySupportPlayer()
	{
		bool bHasBezos = false;
		TArray<FIntPoint> allsupportPos;
		for (AJeff j : PlayerJeffs)
		{
			if (j.TypeJeff == EJeffsType::Bezos)
			{
				bHasBezos = true;
				TArray<FIntPoint> support = j.GetSupport();
				allsupportPos.Append(support);
			}
		}
		for (AJeff& j : PlayerJeffs)
		{
			bool bSupported = false;

			for (const FIntPoint& pos : allsupportPos)
			{
				if (j.PlatformNow.GridX == pos.X && j.PlatformNow.GridY == pos.Y)
				{
					bSupported = true;
					break;
				}
			}

			if (j.JeffSupported != bSupported)
			{
				j.JeffSupported = bSupported;
				j.RecalculateAttack();
			}
		}

		allsupportPos.Empty();
	}
	void ApplySupportEnemy()
	{
		bool bHasBezos = false;
		TArray<FIntPoint> allsupportPos;
		for (AJeff j : PlayerJeffs)
		{
			if (j.TypeJeff == EJeffsType::Bezos)
			{
				bHasBezos = true;
				TArray<FIntPoint> support = j.GetSupport();
				allsupportPos.Append(support);
			}
		}
		for (AJeff& j : EnemyJeffs)
		{
			bool bSupported = false;

			for (const FIntPoint& pos : allsupportPos)
			{
				if (j.PlatformNow.GridX == pos.X && j.PlatformNow.GridY == pos.Y)
				{
					bSupported = true;
					break;
				}
			}

			if (j.JeffSupported != bSupported)
			{
				j.JeffSupported = bSupported;
				j.RecalculateAttack();
			}
		}

		allsupportPos.Empty();
	}
	// ------------------- //
}