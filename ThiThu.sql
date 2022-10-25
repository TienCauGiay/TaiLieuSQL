--Thời gian 60’: Cho CSDL về quản lý bán sách:
use BT1CSDL
go
--1. Tạo View đưa ra danh sách các sách được bán trong tháng 5 năm 2014
create view ThiThu1 as
select tSach.* from tSach join tChiTietHDB on tSach.MaSach = tChiTietHDB.MaSach join tHoaDonBan on tChiTietHDB.SoHDB = tHoaDonBan.SoHDB
where month(tHoaDonBan.NgayBan) = 5 and year(tHoaDonBan.NgayBan) = 2014

select * from ThiThu1

--2. Tạo thủ tục có đầu vào là năm, đầu ra là số lượng sách nhập, sách bán và sách tồn của năm đó
create procedure ThiThu2
@nam int, @slsn int output, @slsb int output, @slst int output
as
begin
	declare @sosachhienco int
	select @slsn = sum(tChiTietHDN.SLNhap) from tHoaDonNhap join tChiTietHDN on tHoaDonNhap.SoHDN = tChiTietHDN.SoHDN
	where year(tHoaDonNhap.NgayNhap) = @nam
	select @slsb = sum(tChiTietHDB.SLBan) from tHoaDonBan join tChiTietHDB on tHoaDonBan.SoHDB = tChiTietHDB.SoHDB
	where year(tHoaDonBan.NgayBan) = @nam
	select @sosachhienco = sum(SoLuong) from tSach
	select @slst = @sosachhienco + @slsn - @slsb
end

declare @slsn int, @slsb int, @slst int
exec ThiThu2 2014, @slsn out, @slsb out, @slst out
print @slsn
print @slsb
print @slst

--3. Tạo hàm đưa ra thông tin Nhân viên sinh nhật trong ngày là tham số nhập vào
create function ThiThu3
(@ns nvarchar(20))
returns table
as return
(
	select * from tNhanVien where NgaySinh = @ns
)

select * from ThiThu3('1990-09-11')

--4. Thêm trường Số lượng sách và Tổng tiền hàng vào bảng nhà cung cấp, cập nhật dữ liệu cho trường này mỗi khi nhập hàng (gồm cả thêm, sửa, xóa).
alter table tNhaCungCap add SoLuongSach int
alter table tNhaCungCap add TongTienHang int

create trigger ThiThu4 on tChiTietHDN
for insert, update, delete
as
begin
	declare @shdnin nvarchar(10), @shdnde nvarchar(10), @msin nvarchar(10), @msde nvarchar(10), @slnin int, @slnde int, @dgin int, @dgde int, @mnccin nvarchar(10), @mnccde nvarchar(10)
	select @shdnin = SoHDN, @msin = MaSach, @slnin = SLNhap from inserted
	select @shdnde = SoHDN, @msde = MaSach, @slnde = SLNhap from deleted
	select @mnccin = MaNCC from tHoaDonNhap where SoHDN = @shdnin
	select @mnccde = MaNCC from tHoaDonNhap where SoHDN = @shdnde
	select @dgin = DonGiaNhap from tSach where MaSach = @msin
	select @dgde = DonGiaNhap from tSach where MaSach = @msde
	update tNhaCungCap set SoLuongSach = isnull(SoLuongSach,0) + @slnin where MaNCC = @mnccin
	update tNhaCungCap set TongTienHang = isnull(TongTienHang,0) + @dgin * @slnin where MaNCC = @mnccin
	update tNhaCungCap set SoLuongSach = isnull(SoLuongSach,0) - @slnde where MaNCC = @mnccde
	update tNhaCungCap set TongTienHang = isnull(TongTienHang,0) - @dgde * @slnde where MaNCC = @mnccde
end

select * from tHoaDonNhap
select * from tChiTietHDN
select * from tNhaCungCap
insert into tChiTietHDN values('HDN01','S04',20,NULL)
update tChiTietHDN set SLNhap = 10 where MaSach = 'S04'
delete from tChiTietHDN where MaSach = 'S03'

--5. Tạo login TranVietAnh, tạo user TranVietAnh cho TranVietAnh trên CSDL QLBanSach
exec sp_addlogin TranVietAnh,123
exec sp_adduser TranVietAnh,TranVietAnh
--Phân quyền Select trên view ở câu 1 cho TranVietAnh và TranVietAnh được phép phân quyền cho người khác
grant select on ThiThu1 to TranVietAnh with grant option
--Đăng nhập TranVietAnh để kiểm tra
--Tạo login NguyenCongHieu, tạo user NguyenCongHieu cho NguyenCongHieu trên CSDL QLBanSach
exec sp_addlogin NguyenCongHieu,123
exec sp_adduser NguyenCongHieu,NguyenCongHieu
--Đăng nhập NguyenCongHieu để kiểm tra
--Từ login TranVietAnh, phân quyền Select trên view Câu 1 cho NguyenCongHieu
grant select on ThiThu1 to NguyenCongHieu
--Đăng nhập NguyenCongHieu để kiểm tra
--6. Tạo View danh sách Nhân viên xuất sắc của tháng 5/2014 bao gồm các nhân viên có tổng hóa đơn nhập và bán là cao nhất trong tháng đó
create view ThiThu6 as
select top 1 with ties MaNV, TenNV, TongSoHoaDon from tNhanVien order by TongSoHoaDon desc
update tNhanVien
set TongSoHoaDon = isnull(b.SHDB,0)
from
(select count(distinct SoHDB) as SHDB, MaNV from tHoaDonBan where month(NgayBan) = 5 and year(NgayBan) = 2014 group by MaNV) b
where tNhanVien.MaNV = b.MaNV 
update tNhanVien
set TongSoHoaDon = isnull(n.SHDN,0)
from
(select count(distinct SoHDN) as SHDN, MaNV from tHoaDonNhap where month(NgayNhap) = 5 and year(NgayNhap) = 2014 group by MaNV) n
where tNhanVien.MaNV = n.MaNV 
