package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Cargo;
import com.hilgo.cargo.entity.Driver;
import com.hilgo.cargo.entity.ShipmentSent;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.entity.enums.CargoSituation;
import com.hilgo.cargo.repository.CargoRepository;
import com.hilgo.cargo.repository.ShipmentSendRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.DriverResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DriverService {

	final private CargoRepository cargoRepository;
	final private UserRepository userRepository;
	final private ShipmentSendRepository shipmentSendRepository;
	
	private String generateDeliveryCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}
	
	public CargoResponse takeCargo(Long cargoId) {
		Cargo cargo = cargoRepository.findById(cargoId)
				.orElseThrow(() -> new RuntimeException("Cargo not found"));
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username)
				.orElseThrow(() -> new RuntimeException("User not found"));
		Driver driver = (Driver)user;
		cargo.setDriver(driver);
		cargo.setCargoSituation(CargoSituation.PICKED_UP);
		cargo.setVerificationCode(generateDeliveryCode());
		cargo.setTakingTime(LocalDateTime.now());
		cargoRepository.save(cargo);
		return CargoResponse.builder()
				.description(cargo.getDescription())
				.selfLocation(cargo.getSelfLocation())
				.targetLocation(cargo.getTargetLocation())
				.measure(cargo.getMeasure())
				.phoneNumber(cargo.getPhoneNumber())
				.cargoSituation(cargo.getCargoSituation())
				.build()
				;
	}

	public boolean deliverCargo(Long cargoId, String verificationCode) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Driver driver = (Driver)userRepository.findByUsername(username).get();
		Cargo cargo = cargoRepository.findByIdAndDriverId(cargoId, driver.getId())
				.orElseThrow(() -> new RuntimeException("Cargo Not found"));
		if (!cargo.getVerificationCode().equals(verificationCode)) {
			throw new RuntimeException("Incorrect verification code");
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
		if (!driverOpt.get().getUsername().equals(driverRequest.getUsername()) && userRepository.existsByUsername(driverRequest.getUsername())) {
			throw new RuntimeException("Username is already exist!");
		}
		if (!driverOpt.get().getMail().equals(driverRequest.getMail()) && userRepository.existsByMail(driverRequest.getMail())) {
			throw new RuntimeException("Mail is already exist!");
		}
		if (!driverOpt.get().getPhoneNumber().equals(driverRequest.getPhoneNumber()) && userRepository.existsByPhoneNumber(driverRequest.getPhoneNumber())) {
			throw new RuntimeException("Phone Number is already exist!");
		}
		if (driverOpt.isPresent()) {
			User driver = driverOpt.get();
			driver.setMail(driverRequest.getMail());
			driver.setPhoneNumber(driverRequest.getPhoneNumber());
			driver.setUsername(driverRequest.getUsername());
			((Driver)driver).setCarType(driverRequest.getCarType());
			userRepository.save(driver);
			return DriverResponse.builder()
					.tc(((Driver)driver).getTc())
					.username(driver.getUsername())
					.carType(driverRequest.getCarType())
					.password(driver.getPassword())
					.phoneNumber(driver.getPhoneNumber())
					.mail(driver.getMail())
					.build();
		}
		else {
			throw new RuntimeException("User Not Found");
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
