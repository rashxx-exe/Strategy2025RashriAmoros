class UJeffsGameInputs : UEnhancedInputComponent
{
    UPROPERTY(Category = "Inputs")
    UInputAction leftClick;

    UPROPERTY(Category = "Inputs")
    UInputAction mouseDraggingMovement;

    UPROPERTY(Category = "Inputs")
    UInputAction Esc;

    UPROPERTY(Category = "Inputs")
    UInputMappingContext ctx;

    AGameController controller;

    AJeffsGameState gs;

// BOOLS //
    bool bDragging = false;
    bool bJeffDragging = false;
    bool escTriggered = false;
    bool jeffUsed = false;
// --------------------- //

    APlatform startPlat;
    
    float count = 0;
    APlatform originalPlat;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        controller = Cast<AGameController>(GetOwner());
        controller.PushInputComponent(this);

        gs = Cast<AJeffsGameState>(GetWorld().GetGameState());

        controller.bShowMouseCursor = true;

        UEnhancedInputLocalPlayerSubsystem InputSubsys = UEnhancedInputLocalPlayerSubsystem::Get(controller);
        InputSubsys.AddMappingContext(ctx, Priority = 1, Options = FModifyContextOptions());

        SetUpPlayerInputComponent();
    }

    UFUNCTION()
    void SetUpPlayerInputComponent()
    {
        BindAction(leftClick,
            ETriggerEvent::Triggered,
            FEnhancedInputActionHandlerDynamicSignature(this, n"LeftClickEventStart"));

        BindAction(leftClick,
            ETriggerEvent::Completed,
            FEnhancedInputActionHandlerDynamicSignature(this, n"LeftClickEventEnd"));
        
        BindAction(mouseDraggingMovement,
            ETriggerEvent::Triggered,
            FEnhancedInputActionHandlerDynamicSignature(this, n"MouseDragg"));

        BindAction(Esc,
            ETriggerEvent::Started,
            FEnhancedInputActionHandlerDynamicSignature(this, n"EscEventStart"));

    }

    UFUNCTION()
    private void LeftClickEventStart(FInputActionValue ActionValue, float32 ElapsedTime, 
                                    float32 TriggeredTime, const UInputAction SourceAction)
    {
        controller.bEnableMouseOverEvents = true;
        controller.bEnableClickEvents = true;
        if (controller == nullptr) return;

        TArray<AActor> toIgnore;
        for (AJeff j : gs.EnemyJeffs) 
            toIgnore.Add(j);

        FCollisionQueryParams Params;
        Params.AddIgnoredActors(toIgnore);
        FHitResult Hit;
        if (!bDragging && !bJeffDragging && !escTriggered && gs.PlayerMoves >= 0)
        {
            if (controller.GetHitResultUnderCursorByChannel(ETraceTypeQuery::Visibility, false, Hit))
            {
                AJeff hitJeff = Cast<AJeff>(Hit.GetActor());
                if (hitJeff != nullptr && IsJeffFromPlayer(hitJeff) && !hitJeff.jeffUsed)
                {
                    originalPlat = hitJeff.PlatformNow;
                    controller.SelectedJeff = hitJeff;
                    bJeffDragging = true;
                    hitJeff.ChangePlatState();
                }
            }
        }

        if (!bJeffDragging && !escTriggered && !gs.isCameraFix && !gs.GamePaused)
        {
            bDragging = true;
        }

    }

    UFUNCTION()
    private void LeftClickEventEnd(FInputActionValue ActionValue, float32 ElapsedTime, 
                                    float32 TriggeredTime, const UInputAction SourceAction)
    {
        controller.bShowMouseCursor = true;

        if (bDragging)
        {
            if (controller.MainHUD != nullptr)
            {
                gs.isSelectOpen = true;
                controller.MainHUD.ChangeMenu();
                
            }
            bDragging = false;
        }

        if (bJeffDragging)
        {
            AJeff jeff = controller.SelectedJeff;
            if (jeff == nullptr)
            {
                bJeffDragging = false;
                controller.SelectedJeff = nullptr;
                return;
            }

            APlatform closest = jeff.GetClosestPlatform(jeff.GetActorLocation());

            AJeff platformOccupied = IsPlatformOccupied(closest);
            
            if (gs.PlayerJeffs.Num() == 0 && !DoSomething())
            {
                //SISTEMA PERDER;
                return;
            }

        //MOVIMIENTO
            if (closest != nullptr && platformOccupied == nullptr && closest.PlatformType == EPlatformType::Movement)
            {
                FVector PlatLoc = closest.GetActorLocation();
                FVector NewLoc = FVector(PlatLoc.X, PlatLoc.Y, jeff.GetActorLocation().Z);

                jeff.SetActorLocation(NewLoc);
                jeff.PlatformNow = closest;
                gs.PlayerMoves -= 1;
                jeff.jeffUsed = true;
                gs.PlayerTurn();
            }
            // SHIELD
            else if (closest != nullptr && closest.PlatformType2 == EPlatformType::Shield && closest.PlatformType == EPlatformType::Attack && platformOccupied != nullptr)
            {
                int targetX = closest.GridX;
                int targetY = closest.GridY - 1;

                APlatform closestShld = nullptr;
                for (int i = 0; i < gs.PlacePlatforms.PlatformsEnemies.Num(); i++)
                {
                    APlatform platform = gs.PlacePlatforms.PlatformsEnemies[i];

                    if (platform.GridX == targetX && platform.GridY == targetY)
                    {
                        closestShld = platform;
                        break;
                    }
                }

                if (closestShld != nullptr)
                {
                    AJeff platformOccupiedShld = IsPlatformOccupied(closestShld);

                    if (platformOccupiedShld != nullptr)
                    {
                        jeff.DealDamage(platformOccupiedShld);
                        jeff.SetActorLocation(FVector(originalPlat.GetActorLocation().X, originalPlat.GetActorLocation().Y, 0));
                        gs.PlayerMoves -= 1;
                        jeff.jeffUsed = true;
                        gs.PlayerTurn();
                    }
                }
            }
        // ATAQUE
            else if (closest != nullptr && closest.PlatformType == EPlatformType::Attack && platformOccupied != nullptr)
            {
                jeff.DealDamage(platformOccupied);
                jeff.SetActorLocation(FVector(originalPlat.GetActorLocation().X, originalPlat.GetActorLocation().Y, 0));
                gs.PlayerMoves -= 1;
                jeff.jeffUsed = true;
                gs.PlayerTurn();
            }
        // CURA
            else if (closest != nullptr && closest.PlatformType == EPlatformType::Healing && platformOccupied != nullptr)
            {
                jeff.Heal(platformOccupied);
                jeff.SetActorLocation(FVector(originalPlat.GetActorLocation().X, originalPlat.GetActorLocation().Y, 0));
                gs.PlayerMoves -= 1;
                jeff.jeffUsed = true;
                gs.PlayerTurn();
            }
            else
            {
                if (originalPlat != nullptr)
                {
                    jeff.SetActorLocation(FVector(originalPlat.GetActorLocation().X, originalPlat.GetActorLocation().Y, 0));
                    jeff.PlatformNow = originalPlat;
                }
            }

            bJeffDragging = false;
            jeff.ResetPlatState();
        }

        controller.SelectedJeff = nullptr;
        gs.ApplySupportPlayer();
    }

    UFUNCTION()
    private void MouseDragg(FInputActionValue ActionValue, float32 ElapsedTime, 
                            float32 TriggeredTime, const UInputAction SourceAction)
    {
        Print("" +  bDragging);
        FVector2D delta = ActionValue.GetAxis2D();

        float sens = 1.0f;

        if (bDragging) {
            if (controller.Camera != nullptr)
            {
                controller.Camera.AddYaw(delta.X * sens);
                controller.Camera.AddPitch(-delta.Y * sens);
            }


            if (controller.MainHUD != nullptr)
            {
                gs.isSelectOpen = false;
                controller.MainHUD.ChangeMenu();
            }
        }

        if (bJeffDragging)
        {
            FVector WorldLoc, WorldDir;
            if (!controller.DeprojectMousePositionToWorld(WorldLoc, WorldDir))
			    return;

            if (!controller.DeprojectMousePositionToWorld(WorldLoc, WorldDir))
                return;

            float TargetZ = controller.SelectedJeff.GetActorLocation().Z;
		    float t = (TargetZ - WorldLoc.Z) / WorldDir.Z;
            FVector NewPos = WorldLoc + WorldDir * t;
            controller.SelectedJeff.SetActorLocation(NewPos);
        }

    }

    UFUNCTION()
    private void EscEventStart(FInputActionValue ActionValue, float32 ElapsedTime,
                               float32 TriggeredTime, const UInputAction SourceAction)
    {
        if (!gs.GameStart) return;
        if (gs.GamePaused)
            escTriggered = true;
        else if (!gs.GamePaused)
            escTriggered = false;

        if (!escTriggered)
        {
            bDragging = false;
            bJeffDragging = false;
            gs.isSelectOpen = false;
            gs.isMenuOpen = true; 

            gs.GamePaused = true;
            controller.MainHUD.ChangeMenu();
        }
        else if (escTriggered)
        {
            if (gs.isSettingsOpen)
            {
                gs.isSettingsOpen = false;
                gs.isMenuOpen = true;
            }
            else 
            {
                gs.isMenuOpen = false;
                gs.GamePaused = false;
                gs.isSelectOpen = true;
            }
            controller.MainHUD.ChangeMenu();
        }        
    }

//FUNCIIONS

    AJeff IsPlatformOccupied(APlatform Platform)
    {
        TArray<AJeff> AllJeffs;
        GetAllActorsOfClass(AllJeffs);
        for (AJeff j : AllJeffs)
        {
            if (j.PlatformNow == Platform)
                return j;
        }
        return nullptr;
    }

    bool IsJeffFromPlayer(AJeff j)
    {
        for (AJeff p : gs.PlayerJeffs)
        {
            if (p == j) return true;
        }
        return false;
    }

    bool DoSomething()
    {
        for (AJeff j : gs.PlayerJeffs)
        {
            if (j == nullptr && j.PlatformNow == nullptr) continue;

            for (FIntPoint m : j.GetMovements())
            {
                int x = j.PlatformNow.GridX + m.X;
                int y = j.PlatformNow.GridY + m.Y;
                for (APlatform p : gs.PlacePlatforms.PlatformsPlayer)
                {
                    if (p.GridX == x && p.GridY == y && gs.IsPlatformOccupied(p) == nullptr) return true;
                }
            }
  
            for (FIntPoint a : j.GetAttacks())
            {
                int x = j.PlatformNow.GridX + a.X;
                int y = j.PlatformNow.GridY + a.Y;
                for (APlatform p : gs.PlacePlatforms.PlatformsPlayer)
                {
                    if (p.GridX == x && p.GridY == y && gs.IsPlatformOccupied(p) == nullptr) return true;
                }
            }
        }

        return false;
    }
}
