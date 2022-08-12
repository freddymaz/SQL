use HotelDatabase;


-- Trigger calculating price of stay
create trigger aft_ins_Bill_calculate_charge 
  on Bill 
    for insert, update
as
  declare @RoomCharge decimal(11,2)
  declare @BoardCharge decimal(11,2)
  declare @BillID int
  declare @ReservationID int

  declare BillCursor cursor for
  select BillID, ReservationID
  from Inserted

  open BillCursor
  fetch next from BillCursor into @BillID, @ReservationID

  while @@FETCH_STATUS = 0
  begin
    -- Calculate how much the room will cost
    select @RoomCharge = datediff(day, res.StartDate, res.EndDate) * rt.PricePerNight
    from Reservation as res
      join Room as r
        on res.RoomID = r.RoomID
      join RoomType as rt
        on r.RoomTypeID = rt.RoomTypeID
    where res.ReservationID = @ReservationID

    update Bill
    set RoomCharge = @RoomCharge
    where BillID = @BillID

    -- Calculate how much the Board will cost, depending on its type, number of people and length of stay
    select @BoardCharge = datediff(day, res.StartDate, res.EndDate) * b.PricePerDay * res.NumOfGuests 
    from Reservation as res
      join Board as b
        on b.BoardID = res.BoardID
    where res.ReservationID = @ReservationID

    update Bill
    set BoardCharge = @BoardCharge
    where BillID = @BillID

    fetch next from BillCursor into @BillID, @ReservationID
  end
  
  close BillCursor
go;

select * from Board
drop trigger aft_ins_Bill_calculate_charge;


-- Trigger will check whether the reserved room is free during the reserving dates
create trigger bef_ins_Res_chk_room_free
  on Reservation
    for insert, update
as
  declare @StartDate date
  declare @EndDate date
  declare @InsertedReservationID int
  declare @InsertedRoomID int
  declare @InsertedStartDate date
  declare @InsertedEndDate date
  declare @ConflictingReservationID int

  declare ReservationCursor cursor for
  select ReservationID, RoomID, StartDate, EndDate
  from Inserted

  open ReservationCursor
  fetch next from ReservationCursor into @InsertedReservationID, @InsertedRoomID, @InsertedStartDate, @InsertedEndDate

  while @@FETCH_STATUS = 0
  begin
    if exists (
      -- Looks at reservations reserving same room as inserted reservation
      -- If reservation dates conflict, it selects
      select *
      from Reservation
      where ReservationID <> @InsertedReservationID and -- Not the same resarvation 
        RoomId = @InsertedRoomID and ( -- Same room 
        @InsertedStartDate between StartDate and EndDate or -- InsertedStartDate is between dates of some reservation 
        @InsertedEndDate between StartDate and EndDate or -- InsertedEndDate is between dates of some reservation 
        (@InsertedStartDate < StartDate and @InsertedEndDate > EndDate) -- Some reservation is between InsertedDates
        )
    )
    begin
      insert into TestDate values (@InsertedReservationID, @InsertedStartDate, @InsertedEndDate)
      ROLLBACK TRANSACTION
      declare @Message nvarchar(255)
      set @Message = N'Error at reservation: ' + cast(@InsertedReservationID as varchar(12)) + ' . Room is already reserved during desired time';
      THROW 60000, @Message, 0;
    end

    fetch next from ReservationCursor into @InsertedReservationID, @InsertedRoomID, @InsertedStartDate, @InsertedEndDate;
  end

  close ReservationCurso
go;

drop trigger bef_ins_Res_chk_room_free;
select * from Reservation;
insert into TestDate values (@StartDate);
select *from TestDate

select * from Reservation

select i.StartDate, i.EndDate, res.StartDate, res.EndDate
from Reservation as i
  join Reservation as res
    on res.RoomID = i.RoomID
where i.ReservationID = 1

create table TestDate (ReservationID int, StartDate date, EndDate date);
delete from TestDate;
select * from TestDate
drop table TestDate












create TRIGGER Kategorie_Dve_Urovne ON Kategorie AFTER INSERT, UPDATE AS
  if (exists (select *
      from inserted
      left join Kategorie on inserted.IdNadrazenaKategorie = Kategorie.Id
      where Kategorie.IdNadrazenaKategorie IS NOT NULL)) -- nad�azen� kategorie je u� podkategorie
    OR (exists (select *
          from inserted
          where inserted.IdNadrazenaKategorie is not null
              and exists(select * from Kategorie where IdNadrazenaKategorie = inserted.Id))) -- kategorie m� podkategorii i nadkategorii
  BEGIN
    ROLLBACK TRANSACTION;
    THROW 60000, 'Kategorie musi byt maximalne dvouurovnove.', 0;
  END;
GO



-- select b.PaymentType, res.StartDate, res.EndDate, rt.PricePerNight, DATEDIFF(day, res.StartDate, res.EndDate) * rt.PricePerNight  AS DateDiff
-- from Bill as b
--   join Reservation as res
--     on b.ReservationID = res.ReservationID
--   join Room as r
--     on res.RoomID = r.RoomID
--   join RoomType as rt
--     on r.RoomTypeID = rt.RoomTypeID




-- select p.BusinessEntityID, p.FirstName, p.LastName, bea.BusinessEntityID, bea.AddressID
-- from Person.Person as p 
--     right join Person.BusinessEntityAddress as bea
--         on p.BusinessEntityID = bea.BusinessEntityID
