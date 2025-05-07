package com.hilgo.cargo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.hilgo.cargo.entity.ShipmentSent;

@Repository
public interface ShipmentSendRepository extends JpaRepository<ShipmentSent, Long>{

}
