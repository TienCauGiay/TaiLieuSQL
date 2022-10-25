	use BT1CSDL
go

--Thủ tục
--1. Tạo thủ tục có đầu vào là mã sách, đầu ra là số lượng sách đó được bán trong năm 2014
create procedure C1
@ms nvarchar(20), @sl int output
as
begin
select @sl = (select sum(tChiTietHDB.SLBan) from tChiTietHDB join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB
where tChiTietHDB.MaSach = @ms and year(tHoaDonBan.NgayBan) = 2014 group by tChiTietHDB.MaSach)
end;

declare @sl int
exec C1 'S01', @sl output
print @sl

--2. Tạo thủ tục có đầu vào là ngày, đầu ra là số lượng hóa đơn và số tiền bán của sách trong ngày đó
create procedure C2
@ngay nvarchar(20), @slhd int output, @stb int output
as
begin
select @slhd = (select count(tHoaDonBan.SoHDB) from tHoaDonBan where NgayBan = @ngay)
select @stb = (select sum(tChiTietHDB.SLBan * tSach.DonGiaBan) from tHoaDonBan join tChiTietHDB on tHoaDonBan.SoHDB = tChiTietHDB.SoHDB
join tSach on tChiTietHDB.MaSach = tSach.MaSach where tHoaDonBan.NgayBan = @ngay)
end;

declare @slhd int, @stb int
exec C2 '2014-8-11', @slhd output, @stb output
print N'Số lượng hóa đơn: ' + case when @slhd > 0 then cast(@slhd as nvarchar) else '0' end
print N'Số tiền bán: ' + case when @stb > 0 then cast(@stb as nvarchar) else '0' end

--3. Tạo thủ tục có đầu vào là mã nhà cung cấp, đầu ra là số đầu sách và số tiền cửa hàng đã nhập của nhà cung cấp đó
create procedure C3
@mncc nvarchar(10), @ss int output, @stn int output
as
begin
select @ss = (select sum(tChiTietHDN.SLNhap) from tHoaDonNhap join tChiTietHDN on tHoaDonNhap.SoHDN = tChiTietHDN.SoHDN
where tHoaDonNhap.MaNCC = @mncc)
select @stn = (select sum(tChiTietHDN.SLNhap * tSach.DonGiaNhap) from tHoaDonNhap join tChiTietHDN on tHoaDonNhap.SoHDN = tChiTietHDN.SoHDN
join tSach on tChiTietHDN.MaSach = tSach.MaSach where tHoaDonNhap.MaNCC = @mncc)
end;

declare @ss int, @stn int
exec C3 N'NCC01', @ss output, @stn output
print N'Số sách nhập: ' + case when @ss > 0 then cast(@ss as nvarchar) else '0' end
print N'Số tiền nhập: ' + case when @stn > 0 then cast(@stn as nvarchar) else '0' end

--4 Tạo thủ tục có đầu vào là năm, đầu ra là số tiền nhập hàng, số tiền bán hàng của năm đó.
create procedure STNB 
@nam nvarchar(50), @STB int output, @STN int output
as 
begin
select @STB = (select sum(tChiTietHDB.SLBan * tSach.DonGiaBan) from tSach inner join tChiTietHDB on tSach.MaSach = tChiTietHDB.MaSach
				inner join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB where year(tHoaDonBan.NgayBan) = @nam)
select @STN = (select sum(tChiTietHDN.SLNhap * tSach.DonGiaNhap) from tSach inner join tChiTietHDN on tSach.MaSach = tChiTietHDN.MaSach
				inner join tHoaDonNhap on tChiTietHDN.SoHDN = tHoaDonNhap.SoHDN where year(tHoaDonNhap.NgayNhap) = @nam)
end;

declare @STB int, @STN int
exec STNB '2014', @STB output, @STN output
print N'Số tiền bán: ' + case when @STB > 0 then cast(@STB as nvarchar) else '0' end
print N'Số tiền nhập: ' + case when @STN > 0 then cast(@STN as nvarchar) else '0' end
--5. Tạo thủ tục có đầu vào là mã NXB, đầu ra là số lượng sách tồn của nhà xuất bản đó
create procedure C5
@mnxb nvarchar(10), @slst int output
as
begin
declare @tsl int, @slb int
select @tsl = (select sum(tSach.SoLuong) from tSach join tNhaXuatBan on tSach.MaNXB = tNhaXuatBan.MaNXB
where tNhaXuatBan.MaNXB = @mnxb)
select @slb = (select sum(tSach.SoLuong) from tSach join tNhaXuatBan on tSach.MaNXB = tNhaXuatBan.MaNXB
where tSach.MaSach not in (select tChiTietHDB.MaSach from tChiTietHDB join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB)
and tNhaXuatBan.MaNXB = @mnxb)
select @slst = @tsl - @slb
end;

declare @slst int
exec C5 'NXB09', @slst output
print N'Số lượng sách tồn: ' + case when @slst > 0 then cast(@slst as nvarchar) else '0' end

--6. Tạo thủ tục nhập dữ liệu cho bảng hóa đơn nhập và chi tiết hóa đơn nhập cùng lúc (sử dụng transaction)

--7. Tạo thủ tục xóa đồng thời hóa đơn bán và chi tiết hóa đơn bán (dùng transaction)

--8. Tạo thủ tục có đầu vào là năm, đầu ra là số lượng sách nhập, sách bán và sách tồn của năm đó
create procedure C8
@nam int, @sn int output, @sb int output, @st int output
as
begin
declare @tsl int
select @sn = (select sum(tChiTietHDN.SLNhap) from tChiTietHDN join tHoaDonNhap on tChiTietHDN.SoHDN = tHoaDonNhap.SoHDN
where year(tHoaDonNhap.NgayNhap) = @nam)
select @sb = (select sum(tChiTietHDB.SLBan) from tChiTietHDB join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB
where year(tHoaDonBan.NgayBan) = @nam)
select @tsl = (select sum(tSach.SoLuong) from tSach)
select @st = @tsl - @sb
end;

declare @sn int, @sb int, @st int
exec C8 2014,@sn output, @sb output, @st output
print N'Số lượng sách nhập: ' + case when @sn > 0 then cast(@sn as nvarchar) else '0' end
print N'Số lượng sách bán: ' + case when @sb > 0 then cast(@sb as nvarchar) else '0' end
print N'Số lượng sách tồn: ' + case when @st > 0 then cast(@st as nvarchar) else '0' end


--Hàm
--10. Tạo hàm đưa ra tổng số tiền đã nhập sách trong một năm với tham số đầu vào là năm
create function C10 
(@nam int)
returns int
as
begin
declare @tstns int
set @tstns = (select sum(tChiTietHDN.SLNhap * tSach.DonGiaNhap) from tSach join tChiTietHDN on tSach.MaSach = tChiTietHDN.MaSach
join tHoaDonNhap on tChiTietHDN.SoHDN = tHoaDonNhap.SoHDN where year(tHoaDonNhap.NgayNhap) = @nam)
return @tstns
end

select dbo.C10(2014) TSTNS

--11. Tạo hàm đưa ra danh sách 10 đầu sách bán chạy nhất trong tháng nào đó (tháng là tham số đầu vào)
create function C11
(@thang int, @nam int)
returns table 
as return 
(
	select * from tSach
	where tSach.MaSach in (select top 10 tChiTietHDB.MaSach from tChiTietHDB join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB
	where MONTH(tHoaDonBan.NgayBan) = @thang and YEAR(tHoaDonBan.NgayBan) = @nam group by tChiTietHDB.MaSach order by 
	sum(tChiTietHDB.SLBan) desc)
)
select c.TenSach from dbo.C11(5,2014) c
--12. Tạo hàm đưa ra danh sách n nhân viên có doanh thu cao nhất trong một năm với n và năm là tham số đầu vào
create function C12
(@n int, @nam int)
returns table
as return 
(
	select * from tNhanVien
	where tNhanVien.MaNV in (select top (@n) tHoaDonBan.MaNV from tHoaDonBan join tChiTietHDB on tHoaDonBan.SoHDB = tChiTietHDB.SoHDB
	join tSach on tChiTietHDB.MaSach = tSach.MaSach where year(tHoaDonBan.NgayBan) = @nam group by tHoaDonBan.MaNV
	order by sum(tChiTietHDB.SLBan * tSach.DonGiaBan) desc)
)

select * from dbo.C12(4,2014)

--13. Tạo hàm đưa ra thông tin khách hàng sinh nhật trong ngày là tham số nhập vào
create function C13
(@sn nvarchar(20))
returns table 
as return
(
	select * from tKhachHang where NgaySinh = @sn
)

select * from tKhachHang
update tKhachHang
set NgaySinh = '2001-5-17' 
where MaKH = 'KH01'

select * from dbo.C13('2001-5-17')

--14. Tạo hàm đưa ra danh sách tồn trong kho quá 2 năm 
create function C14()
returns table
as return
(
	select * from tSach where tSach.MaSach not in (select tChiTietHDB.MaSach from tChiTietHDB
	join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB
	where YEAR(getdate()) - year(NgayBan) < 2)
)

select * from C14()

alter table tChiTietHDB
add DonGia money

alter table tKhachHang
add TongHoaDon money
select * from tKhachHang
create trigger DonGia on tChiTietHDB
for insert, update as
begin
declare @gia money, @masach nvarchar(15), @sohdb nvarchar(10)
select @masach = MaSach, @sohdb = SoHDB from inserted
select @gia = tSach.DonGiaBan from tSach where MaSach = @masach
update tChiTietHDB set DonGia = @gia where MaSach = @masach and SoHDB = @sohdb
end

create trigger C33_trigger on tHoaDonBan
for insert as
begin
	declare @makh nvarchar(10)
	select @makh = MaKH from inserted
	update tKhachHang set SoLuong = isnull(SoLuong,0) + 1 where MaKH = @makh
end

create trigger C4_trigger on tHoaDonBan
for insert, update, delete
as
begin
	declare @makh nvarchar(10)
	select @makh = MaKH from inserted
	update tKhachHang set SoLuong = isnull(SoLuong,0) + 1 where MaKH = @makh
	select @makh = MaKH from deleted
	update tKhachHang set SoLuong = isnull(SoLuong,0) - 1 where MaKH = @makh
end

select * from tKhachHang where MaKH = 'KH04'
insert into tHoaDonBan values ('HDB32', 'NV02', '2014-08-11', 'KH04', null)
select * from tKhachHang where MaKH = 'KH04'
delete from tChiTietHDB where SoHDB in (select SoHDB from tHoaDonBan where MaKH = 'KH04')
delete from tHoaDonBan where MaKH = 'KH04'
select * from tKhachHang where MaKH = 'KH04'

create trigger C5_triiger on tChiTietHDB
for insert, update, delete
as
begin
declare @sohd nvarchar(10), @sosp int
select @sohd = SoHDB, @sosp = sum(SLBan) group by SoHDB from inserted
update tHoaDonBan set SoSanPham = 
end


select * from tHoaDonBan

create trigger C4TreLop_trigger on tHoaDonBan
for insert, update, delete
as
begin
declare @MaKH1 nvarchar(10), @MaKH2 nvarchar(10), @in int, @de int
select @MaKH1 = MaKH, @in = 1 from inserted
select @MaKH2 = MaKH, @in = 1 from deleted
update tKhachHang set SoLuong = isnull(SoLuong,0) + isnull(@in,0) where MaKH = @MaKH1
update tKhachHang set SoLuong = isnull(SoLuong,0) - isnull(@de,0) where MaKH = @MaKH2
end


