package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Cargo;
import com.hilgo.cargo.entity.Driver;
import com.hilgo.cargo.entity.ShipmentSent;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.entity.enums.CargoSituation;
import com.hilgo.cargo.repository.CargoRespository;
import com.hilgo.cargo.repository.DriverRepository;
import com.hilgo.cargo.repository.ShipmentSendRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoesResponse;
import com.hilgo.cargo.response.DriverResponse;
import com.hilgo.cargo.response.ResponseLocation;
import com.hilgo.cargo.response.ResponseMeasure;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DriverService {

	final private CargoRespository cargoRepository;
	final private UserRepository userRepository;
	final private ShipmentSendRepository shipmentSendRepository;
	final private DriverRepository driverRepository;

	private String generateDeliveryCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}

	public Boolean takeCargo(Long cargoId) {
		Cargo cargo = cargoRepository.findById(cargoId).orElseThrow(() -> new RuntimeException("Cargo not found"));
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found"));
		Driver driver = (Driver) user;
		cargo.setDriver(driver);
		cargo.setCargoSituation(CargoSituation.PICKED_UP);
		cargo.setVerificationCode(generateDeliveryCode());
		cargo.setTakingTime(LocalDateTime.now());
		cargoRepository.save(cargo);
		return true;
	}

	public boolean deliverCargo(Long cargoId, String verificationCode) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Driver driver = (Driver) userRepository.findByUsername(username).get();
		Cargo cargo = cargoRepository.findByIdAndDriverId(cargoId, driver.getId())
				.orElseThrow(() -> new RuntimeException("Cargo Not found"));
		if (!cargo.getVerificationCode().equals(verificationCode)) {
			throw new RuntimeException("Incorrect verification code");
		}

		if (shipmentSendRepository.existsByCargo(cargo)) {
        throw new RuntimeException("This cargo has already been delivered!");
    }

		cargo.setCargoSituation(CargoSituation.DELIVERED);
		cargo.setDeliveredTime(LocalDateTime.now());
		cargoRepository.save(cargo);

		ShipmentSent shipmentSent = new ShipmentSent();
		shipmentSent.setCargo(cargo);
		shipmentSent.setDriver(driver);
		shipmentSent.setDistributor(cargo.getDistributor());
		shipmentSent.setDate(LocalDateTime.now());
		shipmentSendRepository.save(shipmentSent);
		return true;
	}

	public DriverResponse updateDriver(DriverRequest driverRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> driverOpt = userRepository.findByUsername(username);
		if (driverOpt.isEmpty()) {
			throw new RuntimeException("User Not Found");
		}
		if (!driverOpt.get().getUsername().equals(driverRequest.getUsername())
				&& userRepository.existsByUsername(driverRequest.getUsername())) {
			throw new RuntimeException("Username is already exist!");
		}
		if (!driverOpt.get().getMail().equals(driverRequest.getMail())
				&& userRepository.existsByMail(driverRequest.getMail())) {
			throw new RuntimeException("Mail is already exist!");
		}
		if (!driverOpt.get().getPhoneNumber().equals(driverRequest.getPhoneNumber())
				&& userRepository.existsByPhoneNumber(driverRequest.getPhoneNumber())) {
			throw new RuntimeException("Phone Number is already exist!");
		}
		if (driverOpt.isPresent()) {
			User driver = driverOpt.get();
			driver.setMail(driverRequest.getMail());
			driver.setPhoneNumber(driverRequest.getPhoneNumber());
			driver.setUsername(driverRequest.getUsername());
			((Driver) driver).setCarType(driverRequest.getCarType());
			userRepository.save(driver);
			return DriverResponse.builder().tc(((Driver) driver).getTc()).username(driver.getUsername())
					.carType(driverRequest.getCarType()).password(driver.getPassword())
					.phoneNumber(driver.getPhoneNumber()).mail(driver.getMail()).build();
		} else {
			throw new RuntimeException("User Not Found");
		}
	}

	public Page<CargoesResponse> getMyCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> userOpt = userRepository.findByUsername(username);
		if (userOpt.isEmpty()) {
			throw new RuntimeException("User not found.");
		}
		Driver driver = (Driver) userOpt.get();

		Page<Cargo> cargoesPage = cargoRepository.findByDriverId(driver.getId(), pageable);
		Page<CargoesResponse> cargoResponse = cargoesPage.map(cargo -> new CargoesResponse(
				cargo.getId(),
				new ResponseLocation(cargo.getSelfLocation().getLatitude(), cargo.getSelfLocation().getLongitude()),
				new ResponseLocation(cargo.getTargetLocation().getLatitude(), cargo.getTargetLocation().getLongitude()),
				new ResponseMeasure(cargo.getMeasure().getWeight(), cargo.getMeasure().getHeight(), cargo.getMeasure().getSize()),
				cargo.getCargoSituation(), 
				cargo.getPhoneNumber(), 
				cargo.getDistributor().getPhoneNumber()));
		return cargoResponse;
	}

	public Page<CargoesResponse> getAllCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Long id = userRepository.findByUsername(username).get().getId();
		Optional<Driver> driverOpt = driverRepository.findById(id);
		if (driverOpt.isEmpty()) {
			throw new RuntimeException("User Not Found");
		}
		Page<Cargo> cargoes = cargoRepository.findAll(pageable);
		Page<CargoesResponse> cargoResponse = cargoes.map(cargo -> new CargoesResponse(
				cargo.getId(),
				new ResponseLocation(cargo.getSelfLocation().getLatitude(), cargo.getSelfLocation().getLongitude()),
				new ResponseLocation(cargo.getTargetLocation().getLatitude(), cargo.getTargetLocation().getLongitude()),
				new ResponseMeasure(cargo.getMeasure().getWeight(), cargo.getMeasure().getHeight(), cargo.getMeasure().getSize()),
				cargo.getCargoSituation(), 
				cargo.getPhoneNumber(), 
				cargo.getDistributor().getPhoneNumber()));
		return cargoResponse;
	}
}
