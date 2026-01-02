UENUM()
enum EJeffsType
{
    Basico,
    Delfin,
    Calabaza,
    Venom,
    Playero,
    Bezos
}

UENUM()
enum EJeffTeam
{
    Player,
    Enemy
}

class AJeff : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent Mesh;
    default Mesh.SetGenerateOverlapEvents(true);
    default Mesh.SetRelativeRotation(FRotator(0, 0, 90));
    default Mesh.SetRelativeLocation(FVector(0, 10, 0));
    default Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
    default Mesh.SetGenerateOverlapEvents(true);
    

    UPROPERTY(DefaultComponent, Attach = "Mesh")
    UCapsuleComponent Collision;
    default Collision.SetGenerateOverlapEvents(true);
    default Collision.SetRelativeLocation(FVector(0, -40, 0));
    default Collision.SetCapsuleRadius(40);
    default Collision.SetCapsuleHalfHeight(80);
    
// 	PLATAFORMAS //
    APlacePlatforms PlacePlatforms;
    APlatform PlatformNow;
// ------------------- //
    
// 	WIDGETS //
    UJeffsPlayingCard JeffPlayingCardBP;
    UWidgetComponent JeffPlayingCard;
// ------------------- //

//  PROPIEDADES //
    int Vida;
    int MaxVida;
    int Ataque;
    int AtaqueBase;
    float MulpAtaque = 1;
    UTexture2D JeffIcon;
    EJeffsType TypeJeff;
    EJeffTeam Team; 
    bool jeffUsed = false;
    FName JeffName;
    bool JeffSupported = false;
// ------------------- //

    AJeffsGameState gs;
    AGameController gc;
    APlayerController pc;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        pc = GetWorld().GameInstance.GetFirstLocalPlayerController();
        gc = Cast<AGameController>(pc);
    }

// CARDS //
    void JeffCreateCard(AJeff Jeff)
    {
        if (gc != nullptr)
        {
            AMainHUD MainHUD = gc.MainHUD;
            if (MainHUD != nullptr)
            {
                MainHUD.MainWidget.AddJeffCard(Jeff);
            }
        }
    }

    UFUNCTION()
    void InitializeFromData(FJeffsData Data)
    {
        if (Data.AActorToSpawn != nullptr)
        {
            Vida = Data.JeffsVida;
            MaxVida = Data.JeffsVida;
            Ataque = Data.JeffsAtaque;
            AtaqueBase = Data.JeffsAtaque;
            JeffIcon = Data.JeffsImg;
            TypeJeff = Data.JeffType;
            JeffName = Data.JeffsName;
        }
    }
// ------------------- //

// VIDA //
    void SetVida(int NewVida)
    {
        Vida = NewVida;
        JeffPlayingCardBP.UpdateLife(NewVida, MaxVida);

        if (Vida == 0)
        {
            bool bIsPlayerAlive = true;
            bool bIsEnemyAlive = true;
    
            if (Team == EJeffTeam::Player)
            {
                gs.PlayerJeffs.Remove(this);
                if (!gs.bJeffAlreadyKilled)
                {
                    gs.bJeffAlreadyKilled = true;
                    gs.PPoints += 2;
                }
                if (TypeJeff == EJeffsType::Bezos)
                {
                    gs.ApplySupportPlayer();
                    Print("Life = 0");
                }
            }
                
            else
            {
                gs.EnemyJeffs.Remove(this);
                if (!gs.bJeffAlreadyKilled)
                {
                    gs.bJeffAlreadyKilled = true;
                    gs.EPoints += 2;
                }
                if (TypeJeff == EJeffsType::Bezos)
                {
                    gs.ApplySupportEnemy();
                    Print("Life = 0");
                }
            }
            DestroyActor();
            JeffPlayingCardBP.RemoveFromParent();
            JeffPlayingCardBP = nullptr;

            if (gs.PlayerJeffs.Num() <= 0)
            {
                bIsPlayerAlive = false;
            }
            else if (gs.EnemyJeffs.Num() <= 0)
            {
                bIsEnemyAlive = false;
            }

            if (!bIsPlayerAlive)
            {
                gs.isSelectOpen = false;
                gs.isEndingOpen = true;
                gs.GamePaused = true;

                if (gc != nullptr)
                {
                    AMainHUD MainHUD = gc.MainHUD;
                    if (MainHUD != nullptr)
                    {
                        MainHUD.JeffEndingWidget.bPlayerWon = false;
                        MainHUD.ChangeMenu();
                    }
                }
            }

            if (!bIsEnemyAlive)
            {
                gs.isSelectOpen = false;
                gs.isEndingOpen = true;;

                if (gc != nullptr)
                {
                    AMainHUD MainHUD = gc.MainHUD;
                    if (MainHUD != nullptr)
                    {
                        MainHUD.JeffEndingWidget.bPlayerWon = true;
                        MainHUD.ChangeMenu();
                    }
                }
            }
            gc.MainHUD.MainWidget.ChangePoints(gs.PPoints);
        }
    }

    void DealDamage(AJeff target)
    {
        int damage = Ataque;
        int newVida = (target.Vida - damage);
        if (newVida <= 0) 
        {
            newVida = 0;
        }
        target.SetVida(newVida);
    }

// ------------------- //

// HEAL / ATTACK //
    void Heal(AJeff target)
    {
        int heal = Ataque;
        int newVida = (target.Vida + heal);
        target.SetVida(newVida);
    }

    void RecalculateAttack()
    {
        if (JeffSupported) MulpAtaque = 2;
        else if (!JeffSupported) MulpAtaque = 1;
        Ataque = int(AtaqueBase * MulpAtaque);
        JeffPlayingCardBP.UpdateAttack(Ataque);
    }
// ------------------- //

// 	GET ATAQUE / MOVIMIENTO / HEAL / SUPPORT // SHIELD

    // GET ADDMOVES //
        void AddSquareMoves(TArray<FIntPoint>& moves, int radio)
        {
            FIntPoint p;
            for (int x = -radio; x <= radio; x++)
                for (int y = -radio; y <= radio; y++)
                {
                    if (x == 0 && y == 0) continue;
                    
                    p.X = x;
                    p.Y = y;
                    moves.Add(p);
                }
        }

        void AddLineMoves(TArray<FIntPoint>& moves, int xmove, int ymove)
        {
            FIntPoint p;

            for (int i = -xmove; i <= xmove; i++)
            {
                if (i == 0) continue;

                if (ymove == 0)
                {
                    p.X = i;
                    p.Y = 0;
                }
                else if (ymove == 1)
                {
                    p.X = 0;
                    p.Y = i;
                }
                
                moves.Add(p);
            }
        }

    // -------------------------

    // GET SUPPORTMOVES //
        void AddSquareSupport(TArray<FIntPoint>& support, int radio)
        {
            FIntPoint p;
            for (int x = -radio; x <= radio; x++)
                for (int y = -radio; y <= radio; y++)
                {
                    if (x == 0 && y == 0) continue;
                    
                    p.X = x;
                    p.Y = y;
                    support.Add(p);
                }
        }
    // -------------------------

    UFUNCTION()
    TArray<FIntPoint> GetMovements()
    {
        TArray<FIntPoint> moves;
        FIntPoint p;

        if (TypeJeff == EJeffsType::Basico || TypeJeff == EJeffsType::Venom || TypeJeff == EJeffsType::Playero)
        {
            AddSquareMoves(moves, 1);
        }
        else if (TypeJeff == EJeffsType::Delfin)
        {
            AddSquareMoves(moves, 2);
        }
        else if (TypeJeff == EJeffsType::Calabaza)
        {
            AddLineMoves(moves, 4, 0);
            AddSquareMoves(moves, 1);
        }
        else if (TypeJeff == EJeffsType::Bezos)
        {
            AddSquareMoves(moves, 2);
        }

        return moves;
    }

    UFUNCTION()
    TArray<FIntPoint> GetAttacks()
    {
        TArray<FIntPoint> attacks;
        FIntPoint p;

        if (TypeJeff == EJeffsType::Basico || TypeJeff == EJeffsType::Venom || TypeJeff == EJeffsType::Playero || TypeJeff == EJeffsType::Bezos)
        {
            for (int dx = -1; dx <= 1; dx++)
                for (int dy = -3; dy <= 0; dy++)
                {
                    p.X = dx; p.Y = dy;
                    attacks.Add(p);
                }
                    
        }
        else if (TypeJeff == EJeffsType::Delfin)
        {
            for (int dy = -4; dy <= 4; dy++)
            {
                p.X = 0;
                p.Y = dy;
                attacks.Add(p);
            }
        }
        
        else if (TypeJeff == EJeffsType::Calabaza)
        {
            for (int dx = -5; dx <= 5; dx++)
                for (int dy = -2; dy <= -2; dy++)
                {
                    p.X = dx; p.Y = dy;
                    attacks.Add(p);
                }
        }

        return attacks;
    }

    UFUNCTION()
    TArray<FIntPoint> GetHealing()
    {
        TArray<FIntPoint> heals;
        FIntPoint p;
        if (Team == EJeffTeam::Player)
        {
            if (TypeJeff == EJeffsType::Playero)
            {
                for (int32 i = 0; i < gs.PlayerJeffs.Num(); i++)
                {
                    AJeff j = gs.PlayerJeffs[i];
                    if (j != nullptr && j != this)
                    {
                        if (j.PlatformNow != nullptr)
                        {
                            p.X = j.PlatformNow.GridX;
                            p.Y = j.PlatformNow.GridY;
                            heals.Add(p);
                        }
                    }
                }
            }
        }

        if (Team == EJeffTeam::Enemy)
        {
            if (TypeJeff == EJeffsType::Playero)
            {
                for (int32 i = 0; i < gs.EnemyJeffs.Num(); i++)
                {
                    AJeff j = gs.EnemyJeffs[i];
                    if (j != nullptr && j != this)
                    {
                        if (j.PlatformNow != nullptr)
                        {
                            p.X = j.PlatformNow.GridX;
                            p.Y = j.PlatformNow.GridY;
                            heals.Add(p);
                        }
                    }
                }
            }
        }
        return heals;
    }

    UFUNCTION()
    TArray<FIntPoint> GetSupport()
    {
        TArray<FIntPoint> support;
        FIntPoint p;

        if (TypeJeff == EJeffsType::Bezos)
        {
            AddSquareSupport(support, 1);
        }

        return support;
    }

    UFUNCTION()
    TArray<FIntPoint> GetShield()
    {
        TArray<FIntPoint> shields;
        FIntPoint p;
        if (Team == EJeffTeam::Player)
        {
            for (int32 i = 0; i < gs.EnemyJeffs.Num(); i++)
            {
                AJeff j = gs.EnemyJeffs[i];
                if (j != nullptr && j != this)
                {
                    if (j.TypeJeff == EJeffsType::Calabaza)
                    {
                        p.X = j.PlatformNow.GridX;
                        p.Y = j.PlatformNow.GridY + 1;
                        shields.Add(p);
                    }
                }
            }
        }
        if (Team == EJeffTeam::Enemy)
        {
            for (int32 i = 0; i < gs.PlayerJeffs.Num(); i++)
            {
                AJeff j = gs.PlayerJeffs[i];
                if (j != nullptr && j != this)
                {
                    if (j.TypeJeff == EJeffsType::Calabaza)
                    {
                        p.X = j.PlatformNow.GridX;
                        p.Y = j.PlatformNow.GridY + 1;
                        shields.Add(p);
                    }
                }
            }           
        }
        return shields;
    }
// ------------------- //

// 	SISTEMA PLATAFORMAS //

    APlatform GetClosestPlatform(FVector Pos)
    {
        if (PlacePlatforms == nullptr && PlacePlatforms.PlatformsPlayer.Num() == 0 && PlacePlatforms.Platforms.Num() == 0) 
        {
            
        }
        float closestDist = 999999;
        APlatform closest = nullptr;

        for (int i = 0; i < PlacePlatforms.Platforms.Num(); i++)
        {
            APlatform Platforms = PlacePlatforms.Platforms[i];            
            float dist = (Platforms.GetActorLocation() - Pos).Size();
            if (dist < closestDist)
            {
                closestDist = dist;
                closest = Platforms;
            }
        }
        return closest;
    }

    void ChangePlatState()
    {
        if (PlacePlatforms == nullptr && PlatformNow == nullptr) return;

        TArray<FIntPoint> moves = GetMovements();
        for (FIntPoint move : moves)
        {
            int targetX = PlatformNow.GridX + move.X;
            int targetY = PlatformNow.GridY + move.Y;

            for (APlatform Platform : PlacePlatforms.PlatformsPlayer)
            {
                if (Platform.GridX == targetX && Platform.GridY == targetY)
                    Platform.ChangeColor(EPlatformType::Movement);
            }
        }

        TArray<FIntPoint> attacks = GetAttacks();
        for (FIntPoint atk : attacks)
        {
            int targetX = PlatformNow.GridX + atk.X;
            int targetY = PlatformNow.GridY + atk.Y;

            for (APlatform Platform : PlacePlatforms.PlatformsEnemies)
            {
                if (Platform.GridX == targetX && Platform.GridY == targetY)
                    Platform.ChangeColor(EPlatformType::Attack);
            }
        }

        TArray<FIntPoint> heals = GetHealing();
        for (FIntPoint hls : heals)
        {
            int targetX = hls.X;
            int targetY = hls.Y;

            for (APlatform Platform : PlacePlatforms.PlatformsPlayer)
            {
                if (Platform.GridX == targetX && Platform.GridY == targetY)
                    Platform.ChangeColor(EPlatformType::Healing);
            }
        }

        TArray<FIntPoint> supportPlat = GetSupport();
        for (FIntPoint spt : supportPlat)
        {
            int targetX = PlatformNow.GridX + spt.X;
            int targetY = PlatformNow.GridY + spt.Y;

            for (APlatform Platform : PlacePlatforms.PlatformsPlayer)
            {
                if (Platform.GridX == targetX && Platform.GridY == targetY)
                    Platform.ChangeColor(EPlatformType::Support);
            }
        }

        TArray<FIntPoint> shields = GetShield();
        for (FIntPoint shld : shields)
        {
            int targetX = shld.X;
            int targetY = shld.Y;

            for (APlatform Platform : PlacePlatforms.PlatformsEnemies)
            {
                if (Platform.GridX == targetX && Platform.GridY == targetY)
                {
                    Platform.ShieldPlat(EPlatformType::Shield);
                }
            }
        }
    }

    void ResetPlatState()
    {
        if (PlacePlatforms == nullptr)
            return;
        for (APlatform Platform : PlacePlatforms.PlatformsPlayer)
            Platform.ChangeColor(EPlatformType::Base);
        for (APlatform Platform : PlacePlatforms.PlatformsEnemies)
        {
            Platform.ChangeColor(EPlatformType::Enemy);
            PlatformNow.ShieldPlat(EPlatformType::Enemy);
        }
    }
// ------------------- //
}